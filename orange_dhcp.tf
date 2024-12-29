# Module parameters
## Orange login (fti/xxxxxxx)
variable "login" {
  type = string
  description = "Orange PPP login"
  validation {
    condition     = can(regex("^fti/[a-z0-9]{7}$", var.login))
    error_message = "The login value must be a valid Orange login, starting with \"fti/\" (found on Orange's welcome email)."
  }
}

## Orange password (6 chars)
variable "password" {
  type = string
  description = "Orange PPP password"
  validation {
    condition     = can(regex("^[a-z0-9]{7}$", var.password))
    error_message = "The login value must be a valid Orange PPP password (found on Orange's welcome email)."
  }
}

## CHAP parameters
variable "chap" {
  type = object({
    id        = string
    challenge = string
  })

  default = {
    id        = "A"
    challenge = "SALTSALTSALTSALT"
  }
}

# We first have to define the char->hex lookup table
# Because terraform cannot do basic shit, seriously?
locals {
  hex_map = {
    " " = "20", "!" = "21", "\"" = "22", "#" = "23", "$" = "24",
    "%" = "25", "&" = "26", "'" = "27", "(" = "28", ")" = "29",
    "*" = "2a", "+" = "2b", "," = "2c", "-" = "2d", "." = "2e",
    "/" = "2f", "0" = "30", "1" = "31", "2" = "32", "3" = "33",
    "4" = "34", "5" = "35", "6" = "36", "7" = "37", "8" = "38",
    "9" = "39", ":" = "3a", ";" = "3b", "<" = "3c", "=" = "3d",
    ">" = "3e", "?" = "3f", "@" = "40", "A" = "41", "B" = "42",
    "C" = "43", "D" = "44", "E" = "45", "F" = "46", "G" = "47",
    "H" = "48", "I" = "49", "J" = "4a", "K" = "4b", "L" = "4c",
    "M" = "4d", "N" = "4e", "O" = "4f", "P" = "50", "Q" = "51",
    "R" = "52", "S" = "53", "T" = "54", "U" = "55", "V" = "56",
    "W" = "57", "X" = "58", "Y" = "59", "Z" = "5a", "[" = "5b",
    "\\"= "5c", "]" = "5d", "^" = "5e", "_" = "5f", "`" = "60",
    "a" = "61", "b" = "62", "c" = "63", "d" = "64", "e" = "65",
    "f" = "66", "g" = "67", "h" = "68", "i" = "69", "j" = "6a",
    "k" = "6b", "l" = "6c", "m" = "6d", "n" = "6e", "o" = "6f",
    "p" = "70", "q" = "71", "r" = "72", "s" = "73", "t" = "74",
    "u" = "75", "v" = "76", "w" = "77", "x" = "78", "y" = "79",
    "z" = "7a", "{" = "7b", "|" = "7c", "}" = "7d", "~" = "7e"
  }
}

# El famoso auth param
output "dhcp_option_auth" {
  # NB: The dhcp 90 for Orange contains the following:
  value = join("", [
    ## 11 Times 0x00, the RFC 3118 header that is not used here
    "0000000000000000000000",

    ## A list of parameters with a type+length header:
    ### An unknown parameter first, a hardcoded one: 1a0900000558010341 (type 1a, length 09 and data 00 00 05 58 01 03 41)
    "1a0900000558010341",

    ### Following that is the Orange login 010d... (type 01, size 0d and data is the hex for the fti/xxxxx login)
    join("", ["01", "", "0d", join("", [for c in split("", var.login) : lookup(local.hex_map, c, "")]) ]),

    ### Then, we have the CHAP challenge "nonce" 3c12... (type 3x, size 16, and data is the hex for the 16 chars challenge)
    join("", ["3c", "", "12", join("", [for c in split("", var.chap.challenge) : lookup(local.hex_map, c, "")]) ]),

    ### Finally, we have the CHAP hash (type 03, size 17, and data is the ID + md5(ID + orange password + challenge))
    join("", ["03", "", "13", lookup(local.hex_map, var.chap.id, ""), md5(join("", [var.chap.id, var.password, var.chap.challenge])) ])
  ])
}

# Pass as a livebox 4
output "dhcp_option_userclass" {
  value = join("", [for c in split("", "+FSVDSL_livebox.Internet.softathome.Livebox4") : lookup(local.hex_map, c, "")])
}

# Also pass as a sagem box
output "dhcp_option_vendor" {
  value = join("", [for c in split("", "sagem") : lookup(local.hex_map, c, "")])
}
