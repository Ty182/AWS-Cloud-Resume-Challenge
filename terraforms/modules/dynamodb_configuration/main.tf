# create dynamodb to store visitor count
# tfsec finding ignored due to cost
#tfsec:ignore:aws-dynamodb-enable-recovery
resource "aws_dynamodb_table" "crc" {
  name         = "cloudresumechallengedb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "app"
  table_class  = "STANDARD"
  # tfsec finding ignored, acceptable risk for this project
  #tfsec:ignore:aws-dynamodb-table-customer-key
  server_side_encryption {
    enabled = true
  }
  attribute {
    name = "app"
    type = "S"
  }
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.crc.arn
}

# create initial table items, alternative is to have lambda create these but this is simplier
resource "aws_dynamodb_table_item" "crc_items" {
  table_name = aws_dynamodb_table.crc.name
  hash_key   = aws_dynamodb_table.crc.hash_key
  item       = <<ITEM
{
  "app": {"S": "cloudresumechallengesite"},
  "views": {"N": "0"}
}
ITEM
}


