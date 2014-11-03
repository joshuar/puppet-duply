class duply::package {
  # TODO: check that the package name is portable across
  # the various distribution families.
  package { 'duply':
    ensure => $duply::ensure,
  }
}
