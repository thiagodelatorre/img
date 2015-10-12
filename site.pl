#!/usr/bin/perl 

use strict;
use warnings;
use utf8;
 require LWP::UserAgent;
 
 our $ua = LWP::UserAgent->new;
 $ua->timeout(60);
 $ua->env_proxy;
 $ua->cookie_jar({file => "cookies.txt"});

our $loginURL = 'https://prenotaonline.esteri.it/login.aspx?cidsede=100001&returnUrl=%2f';
 
my $page = login();
#my $page = getPage($loginURL);
#my %formFields = getForm($page);

print $page;

exit(0);

sub login{
	my $page = getPage($loginURL);
	$page = changeLanguage($page);
	$page = openLogin($page);
	return $page;
}

sub openLogin{
	my $page = $_[0];

	my %formFields = getForm($page);

	delete $formFields{'repLanguages$ctl00$cmdLingua'};
	delete $formFields{'repLanguages$ctl01$cmdLingua'};
	delete $formFields{'BtnRegistrati'};


	foreach my $key (keys %formFields){
		print $key, " = ", $formFields{$key},"\n";
	}
	
	print "Something wrong!\n";
	$page = postPage($loginURL, \%formFields);

	return $page;
}
sub changeLanguage{
	my $page = $_[0];

	my %formFields = getForm($page);
	delete $formFields{'repLanguages$ctl00$cmdLingua'};
	delete $formFields{'BtnRegistrati'};
	delete $formFields{'BtnLogin'};

	$page = postPage($loginURL, \%formFields);
	#print $page;

	return $page;
}

sub postPage{
	my $url = $_[0];
	my $ref_formFields = $_[1];
	my $page = "";

	#foreach my $key (keys %{$ref_formFields}){
	#	print $key, " = ", $ref_formFields->{$key}, "\n";
	#}

	my $response = $ua->post($url, $ref_formFields);

	 if ($response->is_success) {
	     $page = $response->decoded_content;  # or whatever
	 }
	 else {
	     die $response->status_line;
	 }

	return $page;
}

sub fileFromURL{
	my $file = $_[0];
	$file =~ s/\//_/g;
	return $file;
}

sub getPage{
	my $url = $_[0];
	my $file = fileFromURL($url);
	my $page = "";

	if(-e "Cache/".$file){
		open FILE, "< Cache/$file";
		while(<FILE>) { $page .= $_; }
		close FILE;
	} else {
		open FILE, "> Cache/$file";
		
		$page = downloadPage($url);
		print FILE $page;

		close FILE;
	}

	return $page;
}

sub downloadPage{
	my $url = $_[0];
	my $page = "";
 	
	my $response = $ua->get($url);
 
	 if ($response->is_success) {
	     $page = $response->decoded_content;  # or whatever
	 }
	 else {
	     die $response->status_line;
	 }

	return $page;
}

sub getForm{
	my $page = $_[0];
	my $originalPage = $page;
	my %formFields;

	while($originalPage=~/<input[^<]*name="([^"]+)"[^<]*value="([^"]+)"/){
		my ($name,$value)=($1,$2);
		$originalPage=~s/<input[^<]*name="([^"]+)"[^<]*value="([^"]+)"//;
		$formFields{$name}=$value;
	}
	
	foreach my $key (keys %formFields){
		print $key, " = ", $formFields{$key}, "\n";
	}

	return %formFields;
}
