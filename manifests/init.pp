class duply (
  $ensure = $duply::params::ensure,
  ) inherits duply::params {

    anchor {'duply::begin': }
    anchor {'duply::end': }

    # Validate ensure parameter
    if ! ($ensure in [ 'present', 'absent' ]) {
      fail("\"${ensure}\" is not a valid ensure parameter value")
    }

    # Package installation
    class { 'duply::package': }

    # Enforce correct ordering of module components
    if $ensure == 'present' {
      Anchor['duply::begin']
      -> Class['duply::package']
      -> Duply::Profile <| |>
    } else {
      Duply::Profile <| |>
      -> Class['duply::package']
    }
}
