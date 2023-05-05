variable "region" {
  description = "Set your region"
  type = string
  default = "us-east-1"
}

variable "urls" {
  description = "List of urls to send a GET request"
  type = list
}
