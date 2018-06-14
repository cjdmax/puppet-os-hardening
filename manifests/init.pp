# === Copyright
#
# Copyright 2014, Deutsche Telekom AG
# Licensed under the Apache License, Version 2.0 (the "License");
# http://www.apache.org/licenses/LICENSE-2.0
#

# == Class: os_hardening
#
# Pulls in all manifests for os_hardening.
#
class os_hardening (
  String            $system_environment       = 'default',

  Array             $extra_user_paths         = [],
  Optional[String]  $umask                    = undef,
  Optional[String]  $maildir                  = undef,
  Boolean           $usergroups               = true,
  Optional[Integer] $sys_uid_min              = undef,
  Optional[Integer] $sys_gid_min              = undef,
  Integer           $password_max_age         = 60,
  Integer           $password_min_age         = 7,
  Integer           $password_warn_age        = 7,
  Integer           $login_retries            = 5,
  Integer           $login_timeout            = 60,
  String            $chfn_restrict            = '',
  Boolean           $allow_login_without_home = false,
  Integer           $inactivity_expire        = 30,

  Boolean           $allow_change_user        = false,
  Array             $ignore_users             = [],
  Integer           $recurselimit             = 5,
  Boolean           $strict_tcp_wrappers      = false,
  String            $allow_ssh_from           = 'ALL',

  Boolean           $passwdqc_enabled         = true,
  Integer           $auth_retries             = 5,
  Integer           $auth_lockout_time        = 600,
  String            $passwdqc_options         = 'min=disabled,disabled,16,12,8',
  Boolean           $manage_pam_unix          = false,
  Boolean           $enable_pw_history        = true,
  Integer           $pw_remember_last         = 5,
  Boolean           $only_root_may_su         = true,

  Array             $root_ttys                =
    ['console','tty1','tty2','tty3','tty4','tty5','tty6'],

  Array             $whitelist                = [],
  Array             $blacklist                = [],
  Boolean           $remove_from_unknown      = false,
  Boolean           $dry_run_on_unknown       = false,

  Boolean           $enable_module_loading    = true,
  Array             $load_modules             = [],
  Array             $disable_filesystems      =
    ['cramfs','freevxfs','jffs2','hfs','hfsplus','squashfs','udf','vfat'],
  Array             $disable_network_protos   = ['dccp','sctp','rds','tipc'],

  String            $cpu_vendor               = 'intel',
  Boolean           $desktop_enabled          = false,
  Boolean           $enable_ipv4_forwarding   = false,
  Boolean           $manage_ipv6              = true,
  Boolean           $enable_ipv6              = false,
  Boolean           $fully_disable_ipv6       = false,
  Boolean           $enable_ipv6_forwarding   = false,
  Boolean           $arp_restricted           = true,
  Boolean           $enable_sysrq             = false,
  Boolean           $enable_core_dump         = false,
  Boolean           $enable_stack_protection  = true,
  Boolean           $enable_rpfilter          = true,
  Boolean           $enable_log_martians      = true,

  Boolean           $manage_global_bashrc     = false,
  String            $default_umask            = '027',

  Boolean           $enable_auditd            = false,
  Integer           $auditd_max_log_file      = 8,
  Enum['rotate', 'ignore', 'syslog', 'suspend', 'keep_logs']
                    $auditd_max_log_file_action = 'rotate',
  Integer           $auditd_num_logs          = 5,
  Boolean           $apparmor_in_use          = false,
  Boolean           $selinux_in_use           = false,
  Array             $privileged_binaries      = [],

  Array             $unwanted_packages        = ['telnet'],
  Array             $wanted_packages          = ['ntp'],
  Array             $disabled_services        = ['rsync'],
) {

  # Prepare
  # -------

  # system environment configuration
  # there may be differences when using kvm/lxc vs metal

  # sysctl configuration doesn't work in docker:
  $configure_sysctl = (
    $system_environment != 'lxc' and
    $system_environment != 'docker'
  )

  # Defaults for specific platforms
  case $::osfamily {
    'Debian','Suse': {
      $def_umask = '027'
      $def_sys_uid_min = 100
      $def_sys_gid_min = 100
      $shadowgroup = 'shadow'
      $shadowmode = '0640'
    }
    'RedHat': {
      $def_umask = '077'
      $def_sys_uid_min = 201
      $def_sys_gid_min = 201
      $shadowgroup = 'root'
      $shadowmode = '0000'
    }
    default: {
      $def_umask = '027'
      $def_sys_uid_min = 100
      $def_sys_gid_min = 100
      $shadowgroup = 'root'
      $shadowmode = '0600'
    }
  }

  # Merge defaults
  $merged_umask = pick($umask, $def_umask)
  $merged_sys_uid_min = pick($sys_uid_min, $def_sys_uid_min)
  $merged_sys_gid_min = pick($sys_gid_min, $def_sys_gid_min)

  # Install
  # -------
  class { 'os_hardening::limits':
    enable_core_dump => $enable_core_dump,
  }
  class { 'os_hardening::login_defs':
    extra_user_paths         => $extra_user_paths,
    umask                    => $merged_umask,
    maildir                  => $maildir,
    usergroups               => $usergroups,
    sys_uid_min              => $merged_sys_uid_min,
    sys_gid_min              => $merged_sys_gid_min,
    password_max_age         => $password_max_age,
    password_min_age         => $password_min_age,
    password_warn_age        => $password_warn_age,
    login_retries            => $login_retries,
    login_timeout            => $login_timeout,
    chfn_restrict            => $chfn_restrict,
    allow_login_without_home => $allow_login_without_home,
    inactivity_expire        => $inactivity_expire,
  }
  class { 'os_hardening::minimize_access':
    allow_change_user   => $allow_change_user,
    ignore_users        => $ignore_users,
    shadowgroup         => $shadowgroup,
    shadowmode          => $shadowmode,
    recurselimit        => $recurselimit,
    strict_tcp_wrappers => $strict_tcp_wrappers,
    allow_ssh_from      => $allow_ssh_from,
  }
  class { 'os_hardening::modules':
    disable_filesystems   => $disable_filesystems,
  }
  class { 'os_hardening::pam':
    passwdqc_enabled  => $passwdqc_enabled,
    auth_retries      => $auth_retries,
    auth_lockout_time => $auth_lockout_time,
    passwdqc_options  => $passwdqc_options,
    manage_pam_unix   => $manage_pam_unix,
    enable_pw_history => $enable_pw_history,
    pw_remember_last  => $pw_remember_last,
  }
  class { 'os_hardening::profile':
    enable_core_dump => $enable_core_dump,
  }
  class { 'os_hardening::securetty':
    root_ttys => $root_ttys,
  }
  class { 'os_hardening::suid_sgid':
    whitelist           => $whitelist,
    blacklist           => $blacklist,
    remove_from_unknown => $remove_from_unknown,
    dry_run_on_unknown  => $dry_run_on_unknown,
  }

  if $configure_sysctl {
    class { 'os_hardening::sysctl':
      enable_module_loading   => $enable_module_loading,
      load_modules            => $load_modules,
      cpu_vendor              => $cpu_vendor,
      desktop_enabled         => $desktop_enabled,
      enable_ipv4_forwarding  => $enable_ipv4_forwarding,
      manage_ipv6             => $manage_ipv6,
      enable_ipv6             => $enable_ipv6,
      fully_disable_ipv6      => $fully_disable_ipv6,
      enable_ipv6_forwarding  => $enable_ipv6_forwarding,
      arp_restricted          => $arp_restricted,
      enable_sysrq            => $enable_sysrq,
      enable_core_dump        => $enable_core_dump,
      enable_stack_protection => $enable_stack_protection,
      enable_rpfilter         => $enable_rpfilter,
      enable_log_martians     => $enable_log_martians,
    }
  }

  class { 'os_hardening::user_defaults':
    manage_global_bashrc => $manage_global_bashrc,
    default_umask        => $default_umask,
  }

  if $enable_auditd {
    class { 'os_hardening::auditd':
      max_log_file        => $auditd_max_log_file,
      max_log_file_action => $auditd_max_log_file_action,
      num_logs            => $auditd_num_logs,
      selinux_in_use      => $selinux_in_use,
      apparmor_in_use     => $apparmor_in_use,
      privileged_binaries => $privileged_binaries,
    }
  }

  class { 'os_hardening::services':
    unwanted_packages => $unwanted_packages,
    wanted_packages   => $wanted_packages,
    disabled_services => $disabled_services,
  }

}
