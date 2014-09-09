#!/usr/bin/perl
#use strict;
use warnings;
#use Data::Dump qw(dump);
use Net::SMTP::Server;
use Net::SMTP::Server::Client;
use Email::Send;
use MIME::Entity;
use MIME::Parser;
use File::Basename;


# Create a forked process to be controlled by daemon
BEGIN {
 # Fork.
 my $pidFile = '/var/run/pdf_changer.pid';
 my $pid = fork;
 if ($pid) # parent: save PID
 {
  open PIDFILE, ">$pidFile" or die "can't open $pidFile: $!\n";
  print PIDFILE $pid;
  close PIDFILE;
  exit 0;
 }
}


# String Values
my $search_string = "";
my $change_string = "";
my $pdf_name = "";

# Create Empty Strings
my $pdf;

# Start a SMTP server listening on port 10073

my $server = new Net::SMTP::Server('localhost', 10073)
	or die("Unable ot handle client connection: $!\n");
while(my $conn = $server->accept()) {
	my $client = new Net::SMTP::Server::Client($conn) 
		or die("Unable ot handle client connection: $!\n");

	# Process complete tcp mail connection, then restart to listen for next
	$client->process || next;

	# The complete message captured by the SMTP server
#	my $message = $client->{TO} . $client->{FROM} . $client->{MSG};
#	print $message;

	# Parse the email to separate the attachement from the text
	my $parser = new MIME::Parser;
	$parser->output_under("/tmp");
	my $entity = $parser->parse_data($client->{MSG});

	# Loop through the parts of the mime message
	for my $part ($entity->parts) {
		my $type = $part->mime_type;
		# copy the text portion to a string
		if (($type =~ /text/i) || ($type =~/html/i)) {
			$body = $part->bodyhandle->as_string;
		} else { # save the pdf file location and directory to a string
			$pdf = $part->bodyhandle->{MB_Path};
			my $fname = basename($pdf); 
			my $dir = dirname($pdf); 
			$pdf = "$dir/$pdf_name";
			chdir $dir;
			# run the pdftk commands to change the pdf attachment
			system("pdftk $fname output ${fname}_out uncompress");
			system("sed -i 's/$search_string/$change_string/gI' ${fname}_out");
			system("pdftk ${fname}_out output $pdf_name compress");

		}
	}

	# Build a new mime message
	my $top = MIME::Entity->build(	From => $entity->head->get('from'),
					To => $entity->head->get('to'),
					Subject => $entity->head->get('subject'),
					Type => "multipart/mixed",
					Date => $entity->head->get('date'),
					Data => $body);

	# Attach the pdf
	$top->attach(Type => 'application/octet-stream',
			Path => $pdf,
			Encoding => 'base64');


	# Reinject the modified email into postfix
	my $sender = Email::Send->new({mailer => 'SMTP'});
	$sender->mailer_args([Host => 'localhost:10074']);
	$sender->send($top->as_string);
}
