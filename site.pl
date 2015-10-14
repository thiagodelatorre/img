#!/usr/bin/perl 

use strict;
use warnings;
use utf8;
 require LWP::UserAgent;
 
 our $ua = LWP::UserAgent->new(agent=>'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36');
 push @{ $ua->requests_redirectable }, 'POST';
 $ua->timeout(180);
 $ua->env_proxy;
 $ua->cookie_jar({file => "cookies.txt"});

our $baseURL = 'https://prenotaonline.esteri.it/';
our $loginURL = $baseURL.'login.aspx?cidsede=100001&returnUrl=%2f';
our $username=''; our $password='';
 
unless($username=~/thiago/){
	print "Username not set.\n";
	exit(1);
}

my $firstPage = login();
my $done=0;

while($done==0){
	$page = confirmDocLegal($firstPage);
	#my $page = getPage("Test1.html");
	print STDERR "Documents legalization confirmed\n";

	my $hasOpenDays = checkOpenDays($page);
	if($hasOpenDays){
		$page = chooseDay($page);
		#$page = getPage("Test2.html");
		
		$page = confirmDay($page);
		#$page = getPage("Test3.html");
		#printForm($page);

		$page = finishSchedule($page);
		
		$done=1;
		<STDIN>;
	} else {
		print "Not yet.\n";
	}

	sleep(1);
}

exit(0);

sub finishSchedule{
	my $page = $_[0];

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
	my $page = getPage($loginURL);
	print STDERR "Connected\n";
	$page = changeLanguage($page);
	print STDERR "Language Changed\n";
	$page = openLogin($page);
	print STDERR "Login Opened\n";
	$page = clickLogin($page);
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

	my $url = getCaptchaURL($page);
	
	my $captchaFile = fileFromURL($url);

	print "Download captcha from here: $url\n";

	if(-e "Captcha/".$captchaFile){
		#print "Known captcha.\n";
		open FILE, "< Captcha/$captchaFile";
		$captcha = <FILE>;
		chomp $captcha;
		close FILE;
	} else {
		#print "Unknown captcha.\n";
		getCaptchaImage($url);
		system("display \"Cache/$captchaFile\" &");
		print "Enter the solution for the captcha: ";
		$captcha = <STDIN>;
		chomp $captcha;
		open FILE, "> Captcha/$captchaFile";
		print FILE $captcha;
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
	     warn "Connection failed: $response->status_line\n";
	     #$page = $response->status_line;
	 }
	
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

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);

	my $filename = "Log/$year$mon$mday$hour$min$sec.html";
	#print $filename,"\n";
	
	open FILE, "> $filename" || die $!;

	print FILE $page;

	close FILE;
	sleep(1);
}
