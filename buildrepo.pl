#!/usr/bin/perl

use strict;

use Cwd;
use JSON;
use LWP::UserAgent;
use JSON;
use POSIX qw(INT_MAX);
use XML::Simple;
# use Data::Dumper;

use constant INCLUDE_FILE => 'include.json';
use constant REPO_FILE    => 'extensions.xml';
use constant STATS_URL    => 'https://stats.lms-community.org/api/stats/plugins?days=30';
use constant CACHE_FOLDER => '.download-cache';

my $categoriesMap = {
	'Accuradio' => 'radio',
	'AlternativePlayCount' => 'information',
	'ArchiveOrg' => 'musicservices',
	'ARDAudiothek' => 'radio',
	'Audius' => 'musicservices',
	'AutoDisplay' => 'tools',
	'AutoRepo' => 'tools',
	'AutoRescan' => 'scanning',
	'BBCSounds' => 'radio',
	'BookmarkHistory' => 'tools',
	'C3PO' => 'tools',
	'CastBridge' => 'hardware',
	'CBCCanadaFrancais' => 'radio',
	'CDplayer' => 'hardware',
	'CPlus' => 'radio',
	'CustomBrowse' => 'scanning',
	'CustomClockHelper' => 'tools',
	'CustomScan' => 'scanning',
	'CustomSkip' => 'playlists',
	'CustomSkip3' => 'playlists',
	'CustomStartStopTimes' => 'playlists',
	'CustomTagImporter' => 'scanning',
	'DarkDefaultSkin' => 'skin',
	'DatabaseQuery' => 'information',
	'DenonAvpControl' => 'hardware',
	'DenonSerial' => 'hardware',
	'DisableShuffle' => 'playlists',
	'DSDPlayer' => 'hardware',
	'DynamicMix' => 'playlists',
	'DynamicPlayList' => 'playlists',
	'DynamicPlaylistCreator' => 'playlists',
	'DynamicPlaylists4' => 'playlists',
	'FilesViewer' => 'information',
	'FranceTV' => 'radio',
	'FuzzyTime' => 'information',
	'GlobalPlayerUK' => 'radio',
	'Groups' => 'tools',
	'HideMenus' => 'tools',
	'iHeartRadio' => 'radio',
	'InformationScreen' => 'information',
	'InguzEQ' => 'tools',
	'iPeng' => 'skin',
	'IRBlaster' => 'hardware',
	'KidsPlay' => 'tools',
	'KitchenTimer' => 'tools',
	'LazySearch2' => 'scanning',
	'LCI' => 'radio',
	'LicenseManagerPlugin' => 'misc',
	'Live365' => 'radio',
	'LocalPlayer' => 'hardware',
	'MaterialSkin' => 'skin',
	'MixCloud' => 'musicservices',
	'MultiLibrary' => 'scanning',
	'MyQobuz' => 'musicservices',
	'PhilsLibraries' => 'scanning',
	'PlanetRadio' => 'radio',
	'PlayHLS' => 'tools',
	'PlaylistGenerator' => 'playlists',
	'PlaylistMan' => 'playlists',
	'PlayLog' => 'information',
	'PlayWMA' => 'tools',
	'PodcastExt' => 'musicservices',
	'PowerCenter' => 'tools',
	'PowerSave' => 'tools',
	'RadioFavourites' => 'radio',
	'RadioFeedsSBS' => 'radio',
	'RadioFrance' => 'radio',
	'RadioNet' => 'radio',
	'RadioNowPlaying' => 'radio',
	'RaopBridge' => 'hardware',
	'RatingButtons' => 'information',
	'RatingsLight' => 'information',
	'Reliable' => 'misc',
	'SaverSwitcher' => 'information',
	'SettingsManager' => 'tools',
	'SleepFace' => 'tools',
	'ShairTunes2W' => 'hardware',
	'SharkPlay' => 'hardware',
	'SigGen' => 'tools',
	'SimpleLibraryViews' => 'scanning',
	'SongFileViewer' => 'information',
	'SongInfo' => 'information',
	'SongLyrics' => 'information',
	'SpottyBinFreeBSD' => 'misc',
	'Spottyi86pcsolarisBin' => 'misc',
	'SqueezeCLIHandler' => 'tools',
	'SQLPlayList' => 'playlists',
	'SqueezeCLIHandler' => 'misc',
	'SqueezeCloud' => 'musicservices',
	'SqueezeDSP' => 'tools',
	'SqueezeESP32' => 'hardware',
	'SugarCube' => 'playlists',
	'SuperDateTime' => 'information',
	'SwitchGroupPlayer' => 'playlists',
	'SyncOptions' => 'tools',
 	'TIDAL' => 'musicservices',
	'TimesRadio' => 'radio',
	'TitleSwitcher' => 'information',
	'TrackStat' => 'information',
	'TrackStatPlaylist' => 'playlists',
	'TVH' => 'hardware',
	'UPnPBridge' => 'hardware',
	'VirginRadio' => 'radio',
	'VirtualLibraryCreator' => 'scanning',
	'VisualStatistics' => 'information',
	'WaveInput' => 'hardware',
	'Wefunk' => 'radio',
	'xAP' => 'tools',
	'XSqueezeDisplay' => 'information',
	'YouTube' => 'musicservices',
};

my %categories = map { $_ => 1 } values %$categoriesMap;

my $includes;
my $current;

eval {
	open my $fh, '<', INCLUDE_FILE;
	$/ = undef;
	$includes = decode_json(<$fh>);
	close $fh;

	$current = XMLin(REPO_FILE,
		SuppressEmpty => undef,
		KeyAttr => [ 'name' ],
	);
} || die "$@";

my $ua = LWP::UserAgent->new(
	timeout => 5,
	ssl_opts => {
		verify_hostname => 0
	}
);

$ua->agent('Mozilla/5.0, LMS buildrepo (lyrion.org)');

my $statsResp = $ua->get(STATS_URL);
my %stats;

eval {
	map {
		my ($name, $count) = each %$_;
		$stats{$name} = $count;
	} @{ from_json($statsResp->decoded_content) || []};
} or die "Failed to get installation stats: $@";

my $out = {
	details => {
		title => $includes->{title}
	}
};

for my $url (sort @{$includes->{repositories}}) {

	my $resp = $ua->get($url);
	my $content;

	if (!$resp->is_success) {

		warn "error fetching $url - " . $resp->status_line . "\n";

		if ($resp->code == 500) {
			warn "trying curl instead...\n";
			$content = `curl -m35 -L -s $url`;
			$content =~ s/^\s+|\s+$//g;
		}

		if (!$content) {
			my $cache_file = cacheFileName($url);

			if (-f $cache_file) {
				warn "using cached version $cache_file\n";
				open(my $fh, '<:utf8', $cache_file) or warn "Could not read cache file: $!";
				$content = <$fh>;
				close($fh);
			} else {
				warn "no cached version available: $cache_file\n";
			}
		}
	} else {
		# Sourceforge would sometimes redirect in HTML?!? Need to handle these manually:
		if (my $refresh = $resp->header('Refresh')) {
			if ($refresh =~ /url\s*=\s*(.+)$/i) {
				my $next_url = $1;

				# Strip outer single or double quotes if present
				$next_url =~ s/^["']|["']$//g;

				# Resolve relative URLs against the original base URI
				$next_url = URI->new_abs($next_url, $resp->base);

				print "Found Refresh header. Fetching: $next_url\n";
				$resp = $ua->get($next_url);
			}
		}

		$content = $resp->decoded_content;

		my $cache_file = cacheFileName($url);

		# Write content to cache file
		open(my $fh, '>:utf8', $cache_file) or warn "Could not write cache file $cache_file: $!";
		print $fh $content;
		close($fh);
	}

	if ($content) {
		print "$url\n";

		utf8::encode($content);

		my $xml = eval { XMLin($content,
			SuppressEmpty => 1,
			KeyAttr    => [],
			ForceArray => [ 'applet', 'wallpaper', 'sound', 'plugin', 'patch' ],
		) };

		if ($@) {
			print "bad xml ($url): $@\n\n$content\n";
			die "bad xml ($url) $@";
		}

		for my $content (qw(applet wallpaper sound plugin patch)) {
			my $element = $content."s";
			$element =~ s/patchs/patches/;
			for my $item (@{ $xml->{"${element}"}->{"$content"} || [] }) {
				my $name = $item->{'name'};
				delete $item->{installations};	# don't allow dev to define the installation count :-)

				if ($content eq 'plugin') {
					delete $item->{category} if $item->{category} && !$categories{$item->{category}};
					$item->{category} ||= $categoriesMap->{$item->{name}} || 'misc';
					$item->{installations} = $stats{$name} if $stats{$name};
				}

				$item->{link} =~ s/(wiki|forums)\.slimdevices\.com/$1.lyrion.org/;

				if ($item->{desc} && !ref $item->{desc}) {
					$item->{desc} = [{
						lang => 'EN',
						content => $item->{desc}
					}];
				}

				if ($item->{title} && !ref $item->{title}) {
					$item->{title} = [{
						lang => 'EN',
						content => $item->{title}
					}];
				}

				my $currentVersion = eval { $current->{$element}->{$content}->{$name}->{version}; };
				if ($currentVersion && $item->{version} && compareVersions($currentVersion, $item->{version}) > 0) {
					warn "do NOT downgrade - use data from latest committed merged repo file. Current: $currentVersion. 'new': " . $item->{version};
					$item = $current->{$element}->{$content}->{$name};
				}

				print "  $content $name\n";
				push @{ $out->{"${element}"}->{"$content"} ||= [] }, $item;
			}
		}
	}
}

XMLout($out,
	OutputFile => REPO_FILE,
	RootName   => 'extensions',
	KeyAttr    => [ 'name' ],
);

sub cacheFileName {
	my ($cache_file) = @_;
	$cache_file =~ s{^https?://}{};
	$cache_file =~ s/[^a-zA-Z0-9.]/_/g;  # replace non-alphanumeric chars with underscore
	$cache_file = CACHE_FOLDER . '/' . $cache_file;

	mkdir CACHE_FOLDER unless -d CACHE_FOLDER;

	return getcwd() . '/' . $cache_file;
}

# copy of package Slim::Utils::Versions;

sub _parseVersionPart {
	my ($part, $result) = @_;

	if (!$part) {
		return $part;
	}

	my $rest = undef;

	if ($part =~ /^(.+?)\.(.*)$/) {
		$part = $1;
		$rest = $2;
	}

	if ($part eq '*') {

		$result->[0] = POSIX::INT_MAX();
		$result->[1] = '';

	} elsif ($part =~ s/^(-?\d+)//) {

		$result->[0] = $1;
	}

	if ($part && $part eq '+') {

		$result->[0]++;
		$result->[1] = 'pre';

	} elsif ($part && $part =~ /^([A-Za-z]+)?([+-]?\d+)?([A-Za-z]+)?/) {

		$result->[1] = $1 || undef;
		$result->[2] = $2 || 0;
		$result->[3] = $3 || undef;
	}

	return $rest;
}

sub _string_cmp {
	my ($n1, $n2) = @_;

	if (!$n1) {
		return defined $n2;
	}

	if (!$n2) {
		return -1;
	}

	return $n1 cmp $n2;
}

sub _compareVersionPart {
	my ($left, $right) = @_;

	my $ret = $left->[0] <=> $right->[0];

	if ($ret) {
		return $ret;
	}

	$ret = _string_cmp($left->[1], $right->[1]);

	if ($ret) {
		return $ret;
	}

	$ret = $left->[2] <=> $right->[2];

	if ($ret) {
		return $ret;
	}

	return _string_cmp($left->[3], $right->[3]);
}

=head2 compareVersions( $left, $right )

Returns: 1 if $left > $right, 0 if $left == $right, -1 if $left < $right

=cut

sub compareVersions {
	my ($left, $right) = @_;

	my $result;

	if (!$left || !$right) {
		return 1;
	}

	my ($a, $b) = ($left, $right);

	while ($a || $b) {

		my $va = [ 0, undef, 0, undef ];
		my $vb = [ 0, undef, 0, undef ];

		$a = _parseVersionPart($a, $va);
		$b = _parseVersionPart($b, $vb);

		$result = _compareVersionPart($va, $vb);

		if ($result) {
			last;
		}
	}

	return $result || 0;
}

1;
