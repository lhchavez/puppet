class omegaup::grader (
	$root = '/opt/omegaup',
	$user = 'vagrant',
	$embedded_runner = 'true',
	$keystore_password = 'omegaup',
	$mysql_user = 'omegaup',
	$mysql_db = 'omegaup',
	$mysql_host = 'localhost',
	$services_ensure = running,
) {
	# Packages
	package { ['libmysql-java']:
		ensure  => present,
	}
	omegaup::certmanager::cert { "${root}/bin/omegaup.jks":
		hostname => 'localhost',
		password => $keystore_password,
		require  => Vcsrepo[$root],
	}
	file { '/var/log/omegaup/service.log':
		ensure  => 'file',
		owner   => 'omegaup',
		group   => 'omegaup',
		require => File['/var/log/omegaup'],
	}
	file { '/etc/systemd/system/omegaup.service':
		ensure  => 'file',
		source  => "puppet:///modules/omegaup/omegaup.service",
		mode    => '0644',
	}
	file { "${root}/bin/omegaup.conf":
		ensure  => 'file',
		owner   => $user,
		group   => $user,
		mode    => '0644',
		content => template('omegaup/omegaup.conf.erb'),
		require => [Vcsrepo[$root]],
	}
	file { '/tmp/mkhexdirs.sh':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/mkhexdirs.sh',
		mode   => '0700',
	}
	exec { "submissions-directory":
		creates => '/var/lib/omegaup/submissions',
		command => '/tmp/mkhexdirs.sh /var/lib/omegaup/submissions www-data www-data',
		require => [File['/tmp/mkhexdirs.sh'], User['www-data']],
	}
	exec { "grade-directory":
		creates => '/var/lib/omegaup/grade',
		command => '/tmp/mkhexdirs.sh /var/lib/omegaup/grade omegaup omegaup',
		require => [File['/tmp/mkhexdirs.sh'], User['omegaup']],
	}
	file { ['/var/lib/omegaup/compile', '/var/lib/omegaup/input']:
		ensure  => 'directory',
		owner   => 'omegaup',
		group   => 'omegaup',
		require => File['/var/lib/omegaup'],
	}
	service { 'omegaup':
		ensure  => $services_ensure,
		enable  => true,
		provider => 'systemd',
		require => [File['/etc/systemd/system/omegaup.service'],
								Exec['grade-directory'],
								Omegaup::Certmanager::Cert["${root}/bin/omegaup.jks"],
								File["${root}/bin/omegaup.conf"],
								Package['libmysql-java']],
	}
}
