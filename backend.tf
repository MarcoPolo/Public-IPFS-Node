terraform {
  backend "s3" {
    profile        = "marco"
    bucket         = "marcopolo-tf-state"
    key            = "public-ipfs-state"
    region         = "us-west-2"
    # dynamodb_table = "terraform-locking"
    encrypt        = true
  }
}
