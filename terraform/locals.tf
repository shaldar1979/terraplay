locals {
  dag_variables = {
    env1 = {
      api_url  = "https://api.env1.example.com"
      db_name  = "env1_database"
    }
    env2 = {
      api_url  = "https://api.env2.example.com"
      db_name  = "env2_database"
    }
  }
  cidr_block = {
    env1 = "10.10.0.0/16"
    env2 = "10.20.0.0/16"
  }

}
