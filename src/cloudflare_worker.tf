// Copyright 2019-2023 Charles Korn.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// and the Commons Clause License Condition v1.0 (the "Condition");
// you may not use this file except in compliance with both the License and Condition.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// You may obtain a copy of the Condition at
//
//     https://commonsclause.com/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License and the Condition is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See both the License and the Condition for the specific language governing permissions and
// limitations under the License and the Condition.

locals {
  cloudflare_account_id = "4d106699f468851a1f005ce8ae96ba5a"

  # We can't look this up with a data resource without giving access to all zones in the Cloudflare account :sadface:
  cloudflare_zone_id = "b285aeea52df6b888cdee6d2551ebd32"
  domain_name        = "ide-integration.batect.dev"

  paths = [
    "/v1/configSchema.json",
    "/ping",
    "/"
  ]
}

resource "cloudflare_worker_script" "rewrite" {
  name       = "ide_integration_rewrite"
  content    = file("worker.js")
  account_id = local.cloudflare_account_id
}

resource "cloudflare_worker_route" "rewrite" {
  for_each = toset(local.paths)

  zone_id     = local.cloudflare_zone_id
  pattern     = "${local.domain_name}${each.value}"
  script_name = cloudflare_worker_script.rewrite.name
}

resource "cloudflare_record" "dns" {
  name    = "ide-integration"
  type    = "A"
  zone_id = local.cloudflare_zone_id
  value   = "1.1.1.1" # Dummy value, never used.
  proxied = true
}
