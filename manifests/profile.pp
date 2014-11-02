define duply::profile (
  $ensure = $duply::ensure,
  $source,
  $target,
  $gpg_sign_key = undef,
  $gpg_sign_pass = undef,
  $gpg_enc_pass = undef,
  $gpg_enc_key = undef,
  $gpg_opts = undef,
  $target_user = undef,
  $target_pass = undef,
  $max_age = undef,
  $max_full_backups = undef,
  $max_full_with_incrs = undef,
  $max_full_age = undef,
  $volsize = undef,
  $verbosity = 5,
  $temp_dir = undef,
  $arch_dir = undef,
  $dupl_params = undef,
  $source_excludes = undef,
  $cron_weekday = '*',
  $cron_hour = 1,
  $cron_minute = 10,
  ) {
    case $ensure {
      'present': {

        # Make all shellvar types depend on the profile creation
        Shellvar {
          require => Exec["create-duply-profile-${name}"],
        }

        # Defaults for exec types
        Exec {
          path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
          cwd  => '/',
        }

        # Create a profile with duply. Sure, we could use a
        # template instead.
        exec { "create-duply-profile-${name}":
          command => "duply ${name} create",
          creates => "/etc/duply/${name}",
        }

        # Set up a cron job to run the new profile
        cron { "duply_${name}":
          ensure  => 'present',
          command => "duply ${name} backup",
          hour    => $cron_hour,
          minute  => $cron_minute,
          weekday => $cron_weekday,
        }

        # If excludes have been specified, create the exclude file
        # in the profile directory
        if is_array($source_excludes) {
          file { "/etc/duply/${name}/exclude":
            ensure  => 'file',
            content => join($source_excludes,"\n"),
            owner   => 0,
            group   => 0,
            mode    => '0600',
            require => Exec["create-duply-profile-${name}"],
          }
        } else {
          err ( '$excludes should be an array of paths.' )
        }

        # Add the required SOURCE and TARGET config values
        shellvar { "duply_${name}_SOURCE":
          ensure   => 'present',
          target   => "/etc/duply/${name}/conf",
          variable => 'SOURCE',
          value    => $source,
        }
        shellvar { "duply_${name}_TARGET":
          ensure   => 'present',
          target   => "/etc/duply/${name}/conf",
          variable => 'TARGET',
          value    => $target,
        }
        # If a TARGET_USER and TARGET_PASS are supplied add those after
        # some input validation
        if $target_user != undef and $target_pass != undef {
          validate_string($target_user)
          validate_string($target_pass)
          shellvar { "duply_${name}_TARGET_USER":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'TARGET_USER',
            value    => $target_user,
          }
          shellvar { "duply_${name}_TARGET_PASS":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'TARGET_PASS',
            value    => $target_pass,
          }
        } elsif ( $target_user != undef and $target_pass == undef ) or ( $target_user == undef and $target_pass != undef ) {
          fail ( 'Need to define both $target_user and $target_pass' )
        }

        # Warn if GPG_PW is not specified. This means backups are unencrypted
        if $gpg_enc_pass == undef {
          warning ( 'Backups not encrypted!  You need to specify at least $gpg_enc_pass to have backups encrypted.' )
        } else {
          shellvar { "duply_${name}_GPG_PW":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'GPG_PW',
            value    => $gpg_enc_pass,
          }
        }

        # All of the following are shellvar types to add
        # config values.  Some validation is done where
        # possible.

        if $gpg_enc_key != undef {
          shellvar { "duply_${name}_GPG_ENC_KEY":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'GPG_ENC_KEY',
            value    => $gpg_enc_key,
          }
        }

        if $gpg_sign_pass != undef {
          shellvar { "duply_${name}_GPG_SIGN_PW":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'GPG_SIGN_PW',
            value    => $gpg_sign_pass,
          }
        }

        if $gpg_sign_key != undef {
          shellvar { "duply_${name}_GPG_SIGN_KEY":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'GPG_SIGN_KEY',
            value    => $gpg_sign_key,
            }
        }

        if $gpg_opts != undef {
          shellvar { "duply_${name}_GPG_OPTS":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'GPG_OPTS',
            value    => $gpg_opts,
          }
        }

        if $max_age != undef {
          # TODO: work out a validate_re for here...
          shellvar { "duply_${name}_MAX_AGE":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'MAX_AGE',
            value    => $max_age,
          }
        }

        if is_integer($max_full_backups) {
          shellvar { "duply_${name}_MAX_FULL_BACKUPS":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'MAX_FULL_BACKUPS',
            value    => $max_full_backups,
          }
        } elsif $max_full_backups != undef {
          err ( '$max_full_backups defined but not an integer' )
        }

        if is_integer($max_full_with_incrs) {
          shellvar { "duply_${name}_MAX_FULL_WITH_INCRS":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'MAX_FULL_WITH_INCRS',
            value    => $max_full_with_incrs,
          }
        } elsif $max_full_with_incrs != undef {
          err ( '$max_full_with_incrs defined but not an integer' )
        }

        if $max_full_age != undef {
          # TODO: work out a validate_re for here...
          shellvar { "duply_${name}_MAX_FULL_AGE":
            ensure => 'present',
            target => "/etc/duply/${name}/conf",
            variable => 'MAX_FULL_AGE',
            value  => $max_full_age,
          }
        }

        if is_integer($volsize) and $volsize > 0 {
          shellvar { "duply_${name}_VOLSIZE":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'VOLSIZE',
            value    => $volsize,
          }
          $dupl_parms = join($dupl_params,'$DUPL_PARAMS --volsize',$volsize, " ")
        } elsif $volsize != undef {
          err ( '$volsize defined but not an integer' )
        }

        if is_integer($verbosity) {
          shellvar { "duply_${name}_VERBOSITY":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'VERBOSITY',
            value    => $verbosity,
          }
        } elsif $verbosity != undef {
          err ( '$verbosity defined but not an integer' )
        }

        if $temp_dir != undef {
          shellvar { "duply_${name}_TEMP_DIR":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'TEMP_DIR',
            value    => $temp_dir,
          }
        }

        if $arch_dir != undef {
          shellvar { "duply_${name}_ARCH_DIR":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'ARCH_DIR',
            value    => $arch_dir,
          }
        }

        if is_array($dupl_params) {
          $dupl_params = delete_undef_values($dupl_params)
          shellvar { "duply_${name}_DUPL_PARAMS":
            ensure   => 'present',
            target   => "/etc/duply/${name}/conf",
            variable => 'DUPL_PARAMS',
            value    => $dupl_params,
          }
        }
      }
      'absent': {
        file { "/etc/duply/${name}":
          ensure  => 'absent',
          recurse => true,
          purge   => true,
        }

        cron { "duply_${name}":
          ensure  => 'absent',
          command => "duply ${name} backup",
          hour    => $cron_hour,
          minute  => $cron_minute,
          weekday => $cron_weekday,
        }
      }
      default: {
        fail("\"${ensure}\" is not a valid ensure parameter value")
      }
    }
  }
