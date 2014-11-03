define duply::command (
  $ensure = 'present',
  $profile,
  $cron_weekday,
  $cron_hour,
  $cron_minute,
  ) {
    # Validate ensure parameter
    if ! ($ensure in [ 'present', 'absent' ]) {
      fail("\"${ensure}\" is not a valid ensure parameter value")
    }

    # Validate profile exists
    if ! defined(Duply::Profile[$profile]) {
      fail("\"${profile}\" is not a valid duply profile")
    }

    # Set up a cron job to run the command
    cron { "duply_${profile}_${name}":
      ensure  => $ensure,
      command => "duply ${profile} ${name}",
      hour    => $cron_hour,
      minute  => $cron_minute,
      weekday => $cron_weekday,
    }
  }
