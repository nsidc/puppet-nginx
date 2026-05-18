# The stdlib version of this is gone, and to avoid repetative Integer and regex checks, this will help
function nginx::is_integer(Variant[Integer, String] $value) >> Boolean {
  return $value =~ Integer or $value =~ /^-?\d+$/
}