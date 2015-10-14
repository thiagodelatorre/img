#!/usr/bin/perl 

use strict;
use warnings;
use utf8;

while(1){

	my @files = <"Cache/*captcha*">;

	foreach my $captchaFile (@files){
		my $solutionFile = $captchaFile;
		$solutionFile =~ s/Cache/Captcha/;
		unless(-e $solutionFile){
			print $captchaFile, "\n";
			my $pid = system("display -resize 400x176 \"./$captchaFile\" &");
			print "Enter the solution for the captcha: ";
			my $captcha = <STDIN>;
			chomp $captcha;
			if($captcha ne ""){
				open FILE, "> $solutionFile";
				print FILE $captcha;
				close FILE;
			}
			system("killall display");			
		}
	}
	sleep(1); 
}

exit(0);

