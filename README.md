pdf_changer is a postfix before_queue email filter written in perl and designed to alter pdf attachments on-the-fly.

To Use:

1. Install the Module Dependancies
2. Copy pdf_changer.pl to /usr/local/bin/pdf_changer
3. Copy pdf_changer.init to /etc/init.d/pdf_changer
4. Add the content of postfix.master.cf to /etc/postfix/master.cf
5. Turn on the content filter in main.cf by adding content_filter=pdfchg:127.0.0.1:10073
6. Restart postfix and start pdf_changer (service pdf_changer start)
7. Enable the service for reboots (update-rc.d pdf_changer defaults)



Module Dependancies (can be installed with cpan, ex. cpan install Email::Send)

Net::SMTP::Server
Net::SMTP::Server::Client
Email::Send
MIME::Entity
MIME::Parser
File::Basename



