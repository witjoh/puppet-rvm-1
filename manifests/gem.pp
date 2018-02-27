define rvm::gem (
  $ruby,
  $ensure = present,
  $gem = $name,
  $gemset = 'global'
) {
  if $ruby == undef {
     fail("Please provide a $ruby for this gem")
  }

  if is_string($ruby) {
     fail("Please provide a Rvm::Ruby as $ruby for this gem")
  }

  $user = getparam($ruby, "user")
  $ruby_version = getparam($ruby, "version")

  if $ensure == absent {
    $uninstall_command = "gem uninstall --ignore-dependencies -x ${gem}"
    $has_version_check_command = "gem list | grep '^${gem} '"

    rvm::bash_exec { "gem-${gem}-for-${user}-ensure-${ensure}-on-${ruby_version}-in-gemset-${gemset}":
      provider => shell,
      command => $uninstall_command,
      user => $user,
      ruby_version => $ruby_version,
      gemset => $gemset,
      onlyif => $has_version_check_command,
    }
  } else {
    if $ensure == present {
      $command = "gem install ${gem}"
      $check_command = "gem list --local -i ${gem} | grep true"

      rvm::bash_exec { "install-gem-${gem}-for-${user}-ensure-${ensure}-on-${ruby_version}-in-gemset-${gemset}":
        provider => shell,
        command => $command,
        user => $user,
        ruby_version => getparam($ruby, "version"),
        gemset => $gemset,
        unless => $check_command
      }
    } else {
      # we cannot use 'gem list --no-installed ${gem}' here, because e.g. jekyll will match jekyll-sass, too!
      $has_wrong_version_check_command = "gem list --local | grep '^${gem} ' | grep -v '${ensure}'"
      $uninstall_old_version_and_install_new_version_command = "gem uninstall --ignore-dependencies -x ${gem} 2>/dev/null && gem install ${gem}:${ensure}"

      # we cannot use 'gem list --installed ${gem}' here, because e.g. jekyll will match jekyll-sass, too!
      $has_no_version_check_command = "gem list | grep '^${gem} '"
      $install_first_version_command = "gem install ${gem} -v ${ensure}"

      rvm::bash_exec { "reinstall-gem-${gem}-for-${user}-ensure-${ensure}-on-${ruby_version}-in-gemset-${gemset}":
        provider => shell,
        command => $uninstall_old_version_and_install_new_version_command,
        user => $user,
        logoutput => true,
        ruby_version => getparam($ruby, "version"),
        gemset => $gemset,
        onlyif => $has_wrong_version_check_command
      }

      rvm::bash_exec { "install-gem-${gem}-for-${user}-ensure-${ensure}-on-${ruby_version}-in-gemset-${gemset}":
        provider => shell,
        command => $install_first_version_command,
        user => $user,
        logoutput => true,
        ruby_version => getparam($ruby, "version"),
        gemset => $gemset,
        unless => $has_no_version_check_command
      }
    }
  }
}
