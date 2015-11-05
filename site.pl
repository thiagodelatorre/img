#!/usr/bin/perl 

use File::Touch;
use Time::HiRes qw(sleep gettimeofday tv_interval time);
use strict;
use warnings;
use utf8;
require LWP::UserAgent;
 
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

our $savePagefilename = "Log/$year$mon$mday$hour-$min-$sec.html";
our $filesSaved = 0;
our $firstCheck=1;
our $logged=0;
our $currentInterval=0;
our $checks=0;
our $checkLimit=25;
our $targetHour=18;

 our $test=1;

 our $ua = LWP::UserAgent->new(agent=>'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36');
 push @{ $ua->requests_redirectable }, 'POST';
 $ua->timeout(180);
 $ua->env_proxy;
 $ua->cookie_jar({});

our $baseURL = 'https://prenotaonline.esteri.it/';
our $loginURL = $baseURL.'login.aspx?cidsede=100001&returnUrl=%2f';
our $username=''; our $password='';
 
unless($username=~/ccmdlt/){
	print "Username not set.\n";
	exit(1);
}

my $firstPage = login();
my $done=0;

while($done==0){
	my $page = confirmDocLegal($firstPage);
	#my $page = getPage("Test1.html");
	print STDERR "Documents legalization confirmed\n";

	my $hasOpenDays = checkOpenDays($page);
	if($hasOpenDays){
		#savePage($page);
		$page = chooseDay($page);
		#$page = getPage("Test2.html");
		
		#savePage($page);
		$page = confirmDay($page);
		#$page = getPage("Test3.html");
		#printForm($page);

		do{
			#$page = getPage("Test3.html");print "Not yet.\n";
			#savePage($page);
			$page = finishSchedule($page);
			sleep(2);
		}while($page=~/Fascia occupata da altro utente/);
		
		$done=1;
		#<STDIN>;
	} else {
		#print "Not yet. Schedules:" . schedules($page) . "\n";
	}

	my ($sec2,$min2,$hour2,$mday,$mon,$year,$wday,$yday,$isdst) =
		localtime(time);

	if($hour2<$targetHour){
		my $seconds = 
			($targetHour-$hour2-1)*60*60+
			(60-$min2-1)*60+
			(60-$sec2);

		if($seconds>300-$currentInterval && $seconds<360){
			$seconds=300-$currentInterval-60;
		} elsif($seconds>300-$currentInterval){
			$seconds=300-$currentInterval;
		} elsif($seconds>2*$currentInterval){
			$seconds/=2;
		} else {
			$seconds-=$currentInterval;
		}
		
		if($seconds<0) {
			$seconds=1;
		}

		print STDERR "Sleeping for $seconds at $hour2:$min2:$sec2\n";
		sleep($seconds); # Start action at 17:59

	} else {
		sleep(1);
	}
}

exit(0);

sub schedules{
	my $page = $_[0];
	my $schedules = 0;

	if($page=~/ctl00_lblRichieste[^>]+>(\d+)</){
		$schedules = $1;
	}

	return $schedules;
}

sub finishSchedule{
	my $page = $_[0];

	print "Finishing Schedule!!!!!!!!!!!!!!!!!!!!!!!";

	my %formFields = getForm($page);
	delete $formFields{'ctl00$repFunzioni$ctl03$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl02$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$btnFinalBack'};
	delete $formFields{'ctl00$repFunzioni$ctl01$btnMenuItem'};
	delete $formFields{'ctl00$btnLogout'};
	delete $formFields{'ctl00$repFunzioni$ctl00$btnMenuItem'};

	my $captcha = solveCaptcha($page);
	$formFields{'ctl00$ContentPlaceHolder1$captchaConf'}=$captcha;		
	
	#foreach my $key (keys %formFields){
	#	print "$key = $formFields{$key}\n";
	#}

	#print "Captcha sent is $captcha\n";
	$page = postPage($baseURL."acc_Prenota.aspx",\%formFields);

	return $page;
}

sub confirmDay{
	my $page = $_[0];

	my %formFields = getForm($page);
	delete $formFields{'ctl00$btnLogout'};
	delete $formFields{'ctl00$repFunzioni$ctl03$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$acc_Calendario1$myCalendario1$ctl03'};
	delete $formFields{'ctl00$repFunzioni$ctl01$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl00$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$lnkBack'};
	delete $formFields{'ctl00$repFunzioni$ctl02$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$acc_Calendario1$myCalendario1$ctl01'};

	$page = postPage($baseURL."acc_Prenota.aspx",\%formFields);

	return $page;
}

sub chooseDay{
	my $page = $_[0];

	my %formFields = getForm($page);
	delete $formFields{'ctl00$btnLogout'};
	delete $formFields{'ctl00$repFunzioni$ctl02$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl03$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl01$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$lnkBack'};
	delete $formFields{'ctl00$ContentPlaceHolder1$acc_Calendario1$myCalendario1$ctl01'};
	delete $formFields{'ctl00$repFunzioni$ctl00$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$acc_Calendario1$myCalendario1$ctl03'};
	
	$page = postPage($baseURL."acc_Prenota.aspx",\%formFields);

	return $page;
}

sub printForm{
	my $page = $_[0];

	my %formFields = getForm($page);

	foreach my $key (keys %formFields){
		print "$key = $formFields{$key}\n";
	}
}

sub checkOpenDays{
	my $page = $_[0];
	my $hasOpenDays=0;
	my %status;

	if($page=~/<td class="([^"]+)"><input[^<]+value="(\d+)"/){
		my ($status,$day)=($1,$2);

		$status{$day} = $status;
	
		# open status: calendarCellMed
		unless($status eq "otherMonthDay" || 
			$status eq "calendarCellRed" ||
			$status eq "noSelectableDay"){
			$hasOpenDays=1;
			print "Different status found: $status\n";
		}
	}

	return $hasOpenDays;
}

sub login{
	print STDERR "Starting\n";
	my $page = getPage($loginURL);
	print STDERR "Connected\n";
	$page = changeLanguage($page);
	print STDERR "Language Changed\n";
	$page = openLogin($page);
	print STDERR "Login Opened\n";
	$page = clickLogin($page);
	if($page=~/ctl00\$btnLogout/){
		$logged=1;
	} else {
		$logged=1;
		die "Not logged\n";
	}
	print STDERR "Logged in\n";
	$page = clickSchedule($page);
	print STDERR "Schedule clicked\n";
	$page = clickDocLegal($page);
	print STDERR "Documents legalization clicked\n";
	return $page;
}

sub confirmDocLegal{
	my $page = $_[0];
	
	my %formFields = getForm($page);
	delete $formFields{'ctl00$ContentPlaceHolder1$acc_datiAddizionali1$btnAnnulla'};
	delete $formFields{'ctl00$repFunzioni$ctl00$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl03$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl02$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl01$btnMenuItem'};
	delete $formFields{'ctl00$btnLogout'};
	
	#foreach my $key (keys %formFields){
	#	print $key, " = ", $formFields{$key},"\n";
	#}
	
	$page = postPage($baseURL."acc_Prenota.aspx",\%formFields);
	unless($page =~ /ctl00\$btnLogout/){
		$logged=0;
		die "Logged out!\n";
	}

	return $page;
}

sub clickDocLegal{
	my $page = $_[0];

	my %formFields = getForm($page);
	delete $formFields{'ctl00$ContentPlaceHolder1$hiServizio'};
	delete $formFields{'ctl00$ContentPlaceHolder1$acc_breadcrumbServizi1$ctl01'};
	delete $formFields{'ctl00$btnLogout'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl03$h_attivo'};
	delete $formFields{'ctl00$repFunzioni$ctl03$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl01$h_idservizio'};
	delete $formFields{'ctl00$repFunzioni$ctl02$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl01$h_settimane'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl02$h_idservizio'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl03$h_idservizio'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl03$h_bloccato'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl01$h_bloccato'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl02$h_settimane'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl01$btnNomeServizio'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl03$h_settimane'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl02$h_bloccato'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl01$h_attivo'};
	delete $formFields{'ctl00$repFunzioni$ctl01$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl00$btnMenuItem'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl02$h_attivo'};
	delete $formFields{'ctl00$ContentPlaceHolder1$rpServizi$ctl02$btnNomeServizio'};
	delete $formFields{'$ctl02$btnNomeServizio'};

	#foreach my $key (keys %formFields){
	#	print $key, " = ", $formFields{$key},"\n";
	#}
	
	$page = postPage($baseURL."acc_Prenota.aspx",\%formFields);
	
	return $page;
}

sub clickSchedule{
	my $page = $_[0];
	my %formFields = getForm($page);
	delete $formFields{'ctl00$repFunzioni$ctl02$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl03$btnMenuItem'};
	delete $formFields{'ctl00$repFunzioni$ctl01$btnMenuItem'};
	delete $formFields{'ctl00$btnLogout'};

	$page = postPage($baseURL."default.aspx",\%formFields);

	return $page;
}

sub clickLogin{
	my $page = $_[0];
	
	my %formFields = getForm($page);
	delete $formFields{'repLanguages$ctl00$cmdLingua'};
	delete $formFields{'repLanguages$ctl01$cmdLingua'};
	delete $formFields{'BtnRegistrati'};
	delete $formFields{'BtnLogin'};
	delete $formFields{'BtnPwdDimenticataL'};
	$formFields{"UserName"}=$username;
	$formFields{"Password"}=$password;

	my $captcha = solveCaptcha($page);
	$formFields{"loginCaptcha"} = $captcha;

	#foreach my $key (keys %formFields){
	#	print $key, " = ", $formFields{$key},"\n";
	#}

	$page = postPage($loginURL, \%formFields);
	
	return $page;
}

sub solveCaptcha{
	my $page = $_[0];
	my $captcha = "";
	my $trials = 0;

	my $url = getCaptchaURL($page);
	
	my $captchaFile = fileFromURL($url);

	print "Download captcha from here: $url\n";

	unless(-e "Cache/".$captchaFile){
		#print "here $captchaFile\n";
		getCaptchaImage($url);
	}

	until(-e "Captcha/".$captchaFile && -s "Captcha/".$captchaFile){
		$trials++;
		sleep(0.1);
	}

	if($trials==0){
		print "Captcha recicled: $captchaFile\n";
	}

	if(-e "Captcha/".$captchaFile){
		#print "Known captcha.\n";
		open FILE, "< Captcha/$captchaFile" || die "Could not open captcha file";
		$captcha = <FILE>;
		chomp $captcha;
		close FILE;
	}

	return $captcha;
}

sub getCaptchaURL{
	my $page = $_[0];
	my $url = "";

	if($page=~/<img id="[^"]*aptcha[^"]*"[^>]+src="([^"]+)"/){
		$url = $baseURL.$1;
	}

	return $url;
}

sub getCaptchaImage{
	my $url = $_[0];
	my $image = getPage($url);
}

sub openLogin{
	my $page = $_[0];

	my %formFields = getForm($page);

	delete $formFields{'repLanguages$ctl00$cmdLingua'};
	delete $formFields{'repLanguages$ctl01$cmdLingua'};
	delete $formFields{'BtnRegistrati'};


	#foreach my $key (keys %formFields){
	#	print $key, " = ", $formFields{$key},"\n";
	#}
	
	#print "Something wrong!\n";
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

sub logout{
	my $url = $_[0];
	my $ref_formFields = $_[1];
	my %formFields;

	$formFields{'ctl00$btnLogout'} = $ref_formFields->{'ctl00$btnLogout'};	
	$formFields{'__VIEWSTATEGENERATOR'} = $ref_formFields->{'__VIEWSTATEGENERATOR'};	
	$formFields{'__EVENTVALIDATION'} = $ref_formFields->{'__EVENTVALIDATION'};	
	$formFields{'__VIEWSTATE'} = $ref_formFields->{'__VIEWSTATE'};	

	postPage($url,$ref_formFields);

	print STDERR "Logging out ($checks interactions) to prevent blocking\n";

	exit(0);
}

sub postPage{
	my $url = $_[0];
	my $ref_formFields = $_[1];
	my $page = "";

	if($checks==$checkLimit){
		$checks++;
		logout($url, $ref_formFields);
	} else {
		$checks++;
	}

	#foreach my $key (keys %{$ref_formFields}){
	#	print $key, " = ", $ref_formFields->{$key}, "\n";
	#}

	my $i=0;
	my $response;
 
	do{
		if($i>0){
			print STDERR "Trying post $url again\n";
		}
		my $t0 = [gettimeofday()];
		$response = $ua->post($url, $ref_formFields);
		$currentInterval = tv_interval($t0, [gettimeofday()]);
		print STDERR "currentInterval: $currentInterval\n";

		$i++;
		sleep(1) unless($response->is_success);
	}while(!$response->is_success && $i<10);

	 if ($response->is_success) {
	     $page = $response->decoded_content; 
	 }
	 else {
	     die "Connection failed: $response->status_line\n";
	 }
	
	die "Account blocked\n" if($page=~/A conta foi bloqueada/);
	die "Logged out\n" if($page=~/Per ragioni di sicurezza sei stato disconnesso da questo account/);
	
	savePage($page);

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

	if(-e "Cache/".$file && !$test){
		print STDERR "Using page $file from cache.\n";
		open FILE, "< Cache/$file";
		while(<FILE>) { $page .= $_; }
		close FILE;
	} else {
		#if($url=~/pos=2/){
		#	touch("download/".$file); 
		#} else {	
			open FILE, "> Cache/$file";
			$page = downloadPage($url);
			print FILE $page;
			close FILE;
		#} 
	}
	
	savePage($page);
	die "Account blocked\n" if($page=~/A conta foi bloqueada/);
	return $page;
}

sub downloadPage{
	my $url = $_[0];
	my $page = "";

	my $i=0;
	my $response;

	do{
		if($i>0){
			print STDERR "Trying post $url again\n";
		}
		
		$response = $ua->get($url);

		$i++;
		#sleep(2) unless($response->is_success);
	}while(!$response->is_success && $i<10);

	if ($response->is_success) {
		$page = $response->decoded_content; 
	}
	else {
		die "Connection failed: $response->status_line\n";
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
	while($originalPage=~/<input[^<]*name="([^"]+)"/){
		my ($name,$value)=($1,"");
		$originalPage=~s/<input[^<]*name="([^"]+)"//;
		$formFields{$name}=$value;
	}
	
	#foreach my $key (keys %formFields){
	#	print $key, " = ", $formFields{$key}, "\n";
	#}

	return %formFields;
}

sub savePage{
	my $page = $_[0];

	#print $filename,"\n";
	
	open FILE, "> $savePagefilename--$filesSaved" || die $!;

	print FILE $page;

	close FILE;
	$filesSaved++;
	#sleep(1);
}
