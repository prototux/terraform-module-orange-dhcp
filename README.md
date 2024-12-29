# Orange FTTH dhcp options module for terraform

## What?
This is a terraform module implementing Orange's custom auth algorithm (and the 2 other dhcp options, because why not).

## Usage
```terraform
module "orange_dhcp" {
  source = "https://github.com/prototux/terraform-module-orange-dhcp.git"

  login    = "fti/abcdefg" # Replace with your Orange PPP Login, found in the welcome email
  password = "abcdefg"     # Same, replace with your Orange PPP Password found in the same email

  # This is technically optional, but it's a good idea to still define it
  chap     = {
    id        = "A" # A single uppercase letter
    challenge = "abcdefghijlmnopq" # 16 char challenge
  }
}
```
