package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"time"

	"github.com/libp2p/go-libp2p"
	pubsub "github.com/libp2p/go-libp2p-pubsub"
	"github.com/libp2p/go-libp2p/p2p/protocol/circuitv2/relay"
	"github.com/multiformats/go-multiaddr"
)

const topicNameChat = "chat"
const topicNameFiles = "files"

func main() {
	h, err := libp2p.New(libp2p.ListenAddrs(multiaddr.StringCast("/ip4/0.0.0.0/tcp/7654")))
	if err != nil {
		panic(err)
	}

	for _, a := range h.Addrs() {
		withP2p := a.Encapsulate(multiaddr.StringCast("/p2p/" + h.ID().String()))
		fmt.Printf("Address:\t%s\n", withP2p.String())
	}

	ctx, cancelFunc := context.WithCancel(context.Background())

	// create a new PubSub service using the GossipSub router
	ps, err := pubsub.NewGossipSub(ctx, h)
	if err != nil {
		panic(err)
	}

	relayLimits := relay.RelayLimit{
		Data:     1 << 30,       // 1GiB
		Duration: 6 * time.Hour, // 6 hours
	}
	relay, err := relay.New(h, relay.WithLimit(&relayLimits))
	if err != nil {
		panic(err)
	}
	_ = relay

	topicChat, err := ps.Join(topicNameChat)
	if err != nil {
		panic(err)
	}
	topicFiles, err := ps.Join(topicNameFiles)
	if err != nil {
		panic(err)
	}

	go followTopic(ctx, topicFiles)
	go followTopic(ctx, topicChat)

	go func() {
		sub, err := topicFiles.Subscribe()
		if err != nil {
			panic(err)
		}
		sub.Next(ctx)
	}()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	<-c
	cancelFunc()
}

func followTopic(ctx context.Context, t *pubsub.Topic) {
	sub, err := t.Subscribe()
	if err != nil {
		panic(err)
	}

	for ctx.Err() == nil {
		msg, err := sub.Next(ctx)
		if err != nil {
			fmt.Println("error getting next message", err)
		}
		fmt.Println("Get msg:", msg, "from", sub.Topic())
	}
}
