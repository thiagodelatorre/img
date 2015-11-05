#!/usr/bin/perl 

use Time::HiRes qw(sleep);
use strict;
use warnings;
use File::stat;
use utf8;

while(1){

	my @files = 
		map { $_->[1] }
		sort {$a->[0] <=> $b->[0]}
		map { [ stat($_)->ctime, $_ ] }
		glob("Cache/*pos=3*");
	my @files2 = 
		map { $_->[1] }
		sort {$a->[0] <=> $b->[0]}
		map { [ stat($_)->ctime, $_ ] }
		glob("Cache/*pos=2*");

	@files = (@files,@files2);

	foreach my $captchaFile (@files){
		my $solutionFile = $captchaFile;
		$solutionFile =~ s/Cache/Captcha/;
		if(!(-e $solutionFile) && -s $captchaFile){
			print $captchaFile, "\n";
			my $pid = system("display -resize 400x176 \"./$captchaFile\" &");
			my $captcha;
			do{
				print "Enter the solution for the captcha: ";
				$captcha = <STDIN>;
				chomp $captcha;
			}while(length($captcha)%4!=0);
			if($captcha ne ""){
				open FILE, "> $solutionFile";
				print FILE $captcha;
				close FILE;
			}
			system("killall display");			
			last;
		}
	}
	sleep(0.5);
}

exit(0);

