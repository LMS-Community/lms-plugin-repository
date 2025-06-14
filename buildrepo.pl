#!/usr/bin/perl

use strict;

use JSON;
use LWP::UserAgent;
use JSON;
use XML::Simple;
# use Data::Dumper;

use constant INCLUDE_FILE => 'include.json';
use constant REPO_FILE    => 'extensions.xml';
use constant STATS_URL    => 'https://stats.lms-community.org/api/stats/plugins?days=30';

my $categoriesMap = {
	'Accuradio' => 'radio',
	'AlternativePlayCount' => 'information',
	'ArchiveOrg' => 'musicservices',
	'ARDAudiothek' => 'radio',
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

eval {
	open my $fh, '<', INCLUDE_FILE;
	$/ = undef;
	$includes = decode_json(<$fh>);
	close $fh;
} || die "$@";

my $ua = LWP::UserAgent->new(
	timeout => 5,
	ssl_opts => {
		verify_hostname => 0
	}
);

$ua->agent('Mozilla/5.0, LMS buildrepo');

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
	} else {
		$content = $resp->decoded_content;
	}

	if ($content) {
		print "$url\n";

		my $xml = eval { XMLin($content,
			SuppressEmpty => 1,
			KeyAttr    => [],
			ForceArray => [ 'applet', 'wallpaper', 'sound', 'plugin', 'patch' ],
		) };

		if ($@) {
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

1;
