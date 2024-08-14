variable "client" {
    type = string
    description = "Name of the client" 
}

variable "engineers" {
  type = list(string)
  description = "List of users given limited engineer access"
}

variable "read_only" {
  type = list(string)
  description = "List of users only given read only access"
}