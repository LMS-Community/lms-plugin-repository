#!/usr/bin/perl

use strict;

use JSON;
use LWP::UserAgent;
use XML::Simple;
# use Data::Dumper;

use constant INCLUDE_FILE => 'include.json';
use constant REPO_FILE    => 'extensions.xml';

my $categoriesMap = {
	'1001Albums' => 'musicservices',
	'Accuradio' => 'radio',
	'AlternativePlayCount' => 'playlists',
	'ARDAudiothek' => 'radio',
	'AutoDisplay' => 'tools',
	'AutoRepo' => 'tools',
	'AutoRescan' => 'scanning',
	'Bandcamp' => 'musicservices',
	'BBCSounds' => 'radio',
	'BookmarkHistory' => 'tools',
	'C3PO' => 'tools',
	'CastBridge' => 'hardware',
	'CBCCanadaFrancais' => 'radio',
	'CDplayer' => 'hardware',
	'ClientCleanup' => 'tools',
	'CommunityFirmware' => 'tools',
	'CPlus' => 'radio',
	'CustomBrowse' => 'scanning',
	'CustomClockHelper' => 'tools',
	'CustomScan' => 'scanning',
	'CustomSkip' => 'playlists',
	'CustomSkip3' => 'playlists',
	'CustomStartStopTimes' => 'playlists',
	'CustomTagImporter' => 'scanning',
	'DarkDefaultSkin' => 'skin',
	'DatabaseQuery' => 'tools',
	'DenonAvpControl' => 'hardware',
	'DenonSerial' => 'hardware',
	'DisableShuffle' => 'playlists',
	'DRS' => 'radio',
	'DSDPlayer' => 'hardware',
	'DynamicMix' => 'playlists',
	'DynamicPlayList' => 'playlists',
	'DynamicPlaylistCreator' => 'playlists',
	'DynamicPlaylists4' => 'playlists',
	'FilesViewer' => 'tools',
	'FileViewer' => 'tools',
	'FranceTV' => 'radio',
	'GlobalPlayerUK' => 'radio',
	'Groups' => '',
	'HideMenus' => 'tools',
	'IgnoreDirREManager' => 'scanning',
	'iHeartRadio' => 'radio',
	'ImageProxy' => 'tools',
	'InformationScreen' => 'tools',
	'InguzEQ' => 'tools',
	'iPeng' => 'skin',
	'IRBlaster' => 'hardware',
	'LastMix' => 'musicservices',
	'LazySearch2' => 'scanning',
	'LCI' => 'radio',
	'LicenseManagerPlugin' => 'misc',
	'Live365' => 'radio',
	'LocalPlayer' => 'hardware',
	'MaterialSkin' => 'skin',
	'MHCPAN' => 'misc',
	'MixCloud' => 'musicservices',
	'MultiLibrary' => 'scanning',
	'MusicArtistInfo' => 'musicservices',
	'MusicInfoSCR' => 'tools',
	'NoSetup' => 'tools',
	'PhilsLibraries' => '',
	'Phishin' => 'radio',
	'PlanetRadio' => 'radio',
	'PlayHistory' => 'tools',
	'PlayHLS' => 'tools',
	'PlaylistGenerator' => 'playlists',
	'PlaylistMan' => 'playlists',
	'PlayLost' => 'tools',
	'PlayWMA' => 'tools',
	'PodcastExt' => 'radio',
	'Qobuz' => 'musicservices',
	'RadioFavourites' => 'radio',
	'RadioFeedsSBS' => 'radio',
	'RadioFrance' => 'radio',
	'RadioNet' => 'radio',
	'RadioNowPlaying' => 'radio',
	'RadioParadise' => 'radio',
	'RaopBridge' => 'hardware',
	'RatingButtons' => 'tools',
	'RatingsLight' => 'tools',
	'Reliable' => 'misc',
	'ShairTunes2W' => 'hardware',
	'SharkPlay' => 'hardware',
	'SigGen' => 'tools',
	'SimpleLibraryViews' => 'scanning',
	'SongFileViewer' => 'tools',
	'SongInfo' => 'tools',
	'SongLyrics' => 'tools',
	'Spotty' => 'musicservices',
	'SpottyARMLegacyBin' => 'musicservices',
	'SpottyARMPi0Bin' => 'musicservices',
	'SpottyBinFreeBSD' => 'musicservices',
	'Spottyi86pcsolarisBin' => 'musicservices',
	'SQLPlayList' => 'playlists',
	'SqueezeCLIHandler' => 'misc',
	'SqueezeDSP' => 'tools',
	'SqueezeESP32' => 'hardware',
	'SugarCube' => 'musicservices',
	'SwitchGroupPlayer' => 'playlists',
	'TimeSpeller' => 'tools',
	'TimesRadio' => 'radio',
	'TitleSwitcher' => 'tools',
	'TrackStat' => 'tools',
	'TrackStatPlaylist' => 'playlists',
	'UPnPBridge' => 'hardware',
	'VirginRadio' => 'radio',
	'VirtualLibraryCreator' => 'scanning',
	'VisualStatistics' => 'tools',
	'WaveInput' => 'hardware',
	'WalkWithMe' => 'tools',
	'Wefunk' => 'radio',
	'xAP' => 'misc',
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
			warn "bad xml ($url) $@";
			next;
		}

		for my $content (qw(applet wallpaper sound plugin patch)) {
			my $element = $content."s";
			$element =~ s/patchs/patches/;
			for my $item (@{ $xml->{"${element}"}->{"$content"} || [] }) {
				my $name = $item->{'name'};

				if ($content eq 'plugin') {
					delete $item->{category} if $item->{category} && !$categories{$item->{category}};
					$item->{category} ||= $categoriesMap->{$item->{name}} || 'misc';
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

1;
