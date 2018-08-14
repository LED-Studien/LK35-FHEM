##############################################
# $Id: 32_LK32.pm 7570 2018-08-13 15:15:44Z oliverschoenefeld $
#
# maintainer: LED-Studien GmbH, oli@led-studien.de
#

package main;

use strict;
use warnings;
use IO::Socket;

sub
LK35_Initialize(@)
{
  my ($hash) = @_;

  $hash->{DefFn}        = "LK35_Define";
  $hash->{UndefFn}      = "LK35_Undef";
  $hash->{SetFn}        = "LK35_Set";
  $hash->{GetFn}        = "LK35_Get";

  return undef;
}

sub
LK35_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  return "wrong syntax: define <name> LK35 <LEDTYPE> <IP>" if(@a != 4);
  my $name = $a[0];
  return "only <LEDTYPE> 'DIM', 'CCT' and 'RGBW' are supported." if(($a[2] ne "DIM") and ($a[2] ne "CCT") and ($a[2] ne "RGBW"));
  $hash->{LEDTYPE} = $a[2];
  if ($a[3] =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):*(\d+)*/g)
  {
    $hash->{STATE} = 'off';
    $hash->{IP} = $1;
    $hash->{PORT} = $2?$2:8899;
  }
  else
  {
    return "Please provide a valid IPv4 address \n\ni.e. \n192.168.1.28";
  }
  if (!defined($hash->{helper}->{SOCKET}))
  {
    my $sock = IO::Socket::INET-> new (
      PeerPort => $hash->{PORT},
      PeerAddr => $hash->{IP},
      Timeout => 1,
      Blocking => 0,
      Proto => 'tcp') or Log3 ($hash, 3, "define $hash->{NAME}: can't reach ($@)");
    my $select = IO::Select->new($sock);
    $hash->{helper}->{SOCKET} = $sock;
    $hash->{helper}->{SELECT} = $select;
  }
  if($hash->{LEDTYPE} eq 'DIM')
  {
    readingsBeginUpdate($hash);
	  readingsBulkUpdate($hash, "brightness", 0);
	  readingsEndUpdate($hash, 1);
  }
  elsif($hash->{LEDTYPE} eq 'CCT')
  {
    readingsBeginUpdate($hash);
	  readingsBulkUpdate($hash, "brightness", 0);
    readingsBulkUpdate($hash, "WW", 0);
    readingsBulkUpdate($hash, "CW", 0);
    readingsBulkUpdate($hash, "CCT", 0);
	  readingsEndUpdate($hash, 1);
  }
  elsif($hash->{LEDTYPE} eq 'RGBW')
  {
    readingsBeginUpdate($hash);
	  readingsBulkUpdate($hash, "brightness", 0);
    readingsBulkUpdate($hash, "R", 0);
    readingsBulkUpdate($hash, "G", 0);
    readingsBulkUpdate($hash, "B", 0);
    readingsBulkUpdate($hash, "W", 0);
    readingsBulkUpdate($hash, "RGB", "000000");
    readingsBulkUpdate($hash, "RGBW", "00000000");
	  readingsEndUpdate($hash, 1);
  }

  return undef;
}

sub
LK35_Undef(@)
{
  return undef;
}

sub
LK35_Set(@)
{
  my ($Device, $name, $cmd, @args) = @_;

  #command checking
  if($Device->{LEDTYPE} eq 'RGBW')
  {
    return "Unknown argument $cmd, choose one of R G B W RGB RGBW dim dimup dimdown on off" if
      (
        ($cmd ne 'R') and
        ($cmd ne 'G') and
        ($cmd ne 'B') and
        ($cmd ne 'W') and
        ($cmd ne 'RGB') and
        ($cmd ne 'RGBW') and
        ($cmd ne 'dim') and
        ($cmd ne 'dimup') and
        ($cmd ne 'dimdown') and
        ($cmd ne 'on') and
        ($cmd ne 'off')
      );
  }
  elsif ($Device->{LEDTYPE} eq 'CCT')
  {
    return "Unknown argument $cmd, choose one of CW WW CCT dim dimup dimdown on off" if
      (
        ($cmd ne 'WW') and
        ($cmd ne 'CW') and
        ($cmd ne 'CCT') and
        ($cmd ne 'dim') and
        ($cmd ne 'dimup') and
        ($cmd ne 'dimdown') and
        ($cmd ne 'on') and
        ($cmd ne 'off')
      );
  }
  else
  {
    return "Unknown argument $cmd, choose one of dim dimup dimdown on off" if
      (
        ($cmd ne 'dim') and
        ($cmd ne 'dimup') and
        ($cmd ne 'dimdown') and
        ($cmd ne 'on') and
        ($cmd ne 'off')
      );
  }

  #value checking
  if(($cmd eq 'R') or ($cmd eq 'G') or ($cmd eq 'B') or ($cmd eq 'W') or ($cmd eq 'WW') or ($cmd eq 'CW') or ($cmd eq 'CCT'))
  {
    return "one value must be specified for a channel command" if (@args != 1);
    return "only values 0 to 255 allowed for channel command" if ($args[0] !~ m/^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/g );
  }
  elsif($cmd eq 'RGB')
  {
    return "one value must be specified for RGB command" if (@args != 1);
    return "only hex values like FFFFFF allowed for RGB command" if ($args[0] !~ m/^([0-9A-Fa-f]{6})$/g );
  }
  elsif($cmd eq 'RGBW')
  {
    return "one value must be specified for RGBW command" if (@args != 1);
    return "only hex values like FFFFFFFF allowed for RGBW command" if ($args[0] !~ m/^([0-9A-Fa-f]{8})$/g );
  }
  elsif(($cmd eq 'dim'))
  {
    return "one value must be specified for a dim command" if (@args != 1);
    return "only values 0 to 255 allowed for dim command" if ($args[0] !~ m/^1?[0-9]{1,2}|2[0-4][0-9]|25[0-5]$/g );
  }
  else
  {
    return "no value must be specified for dimup, dimdown, on, off commands" if (@args != 0);
  }

  #create packages according to command
  #my $msg = pack('C*', 0x55, Device1, Device2, Device3, 0x02, Zone, Category, Channel, Value, Checksum, 0xAA, 0xAA );

  my $msg;
  if($cmd eq 'R')
  {
      my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
      $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
      my $rgbw_old = ReadingsVal($Device->{NAME}, "RGBW", undef);
      my $rgbw_new = sprintf("%02X",$args[0]).substr($rgbw_old, 2, 6);
      my $rgb_new = substr($rgbw_new, 0, 6);
      readingsBeginUpdate($Device);
      readingsBulkUpdate($Device, "R", $args[0]);
      readingsBulkUpdate($Device, "RGB", $rgb_new);
      readingsBulkUpdate($Device, "RGBW", $rgbw_new);
      readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'G')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    my $rgbw_old = ReadingsVal($Device->{NAME}, "RGBW", undef);
    my $rgbw_new = substr($rgbw_old, 0, 2).sprintf("%02X",$args[0]).substr($rgbw_old, 4, 4);
    my $rgb_new = substr($rgbw_new, 0, 6);
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "G", $args[0]);
    readingsBulkUpdate($Device, "RGB", $rgb_new);
    readingsBulkUpdate($Device, "RGBW", $rgbw_new);
    readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'B')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    my $rgbw_old = ReadingsVal($Device->{NAME}, "RGBW", undef);
    my $rgbw_new = substr($rgbw_old, 0, 4).sprintf("%02X",$args[0]).substr($rgbw_old, 6, 2);
    my $rgb_new = substr($rgbw_new, 0, 6);
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "B", $args[0]);
    readingsBulkUpdate($Device, "RGB", $rgb_new);
    readingsBulkUpdate($Device, "RGBW", $rgbw_new);
    readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'W')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    my $rgbw_old = ReadingsVal($Device->{NAME}, "RGBW", undef);
    my $rgbw_new = substr($rgbw_old, 0, 6).sprintf("%02X",$args[0]);
    my $rgb_new = substr($rgbw_new, 0, 6);
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "W", $args[0]);
    readingsBulkUpdate($Device, "RGBW", $rgbw_new);
    readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'WW')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    readingsSingleUpdate($Device, "WW", $args[0], 1);
  }
  elsif($cmd eq 'CW')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, $args[0]/512*$brightness, 0x00, 0xAA, 0xAA));
    readingsSingleUpdate($Device, "CW", $args[0], 1);
  }
  elsif($cmd eq 'CCT')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    my $ww = $args[0];
    my $cw = 255-$args[0];
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $ww/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $cw/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $ww/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, $cw/512*$brightness, 0x00, 0xAA, 0xAA));
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "WW", $args[0]);
    readingsBulkUpdate($Device, "CW", 255-$args[0]);
    readingsBulkUpdate($Device, "CCT", $args[0]);
	  readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'RGB')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    my $r = hex substr($args[0], 0, 2);
		my $g = hex substr($args[0], 2, 2);
		my $b = hex substr($args[0], 4, 2);
    print "r:$r";
    print "g:$g";
    print "b:$b";
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $r/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $g/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $b/512*$brightness, 0x00, 0xAA, 0xAA));
    my $rgbw = $args[0] . substr(ReadingsVal($Device->{NAME}, "RGBW", undef), 6, 2);
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "R", $r);
    readingsBulkUpdate($Device, "G", $g);
    readingsBulkUpdate($Device, "B", $b);
    readingsBulkUpdate($Device, "RGB", $args[0]);
    readingsBulkUpdate($Device, "RGBW", $rgbw);
	  readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'RGBW')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    my $r = hex substr($args[0], 0, 2);
		my $g = hex substr($args[0], 2, 2);
		my $b = hex substr($args[0], 4, 2);
		my $w = hex substr($args[0], 6, 2);
    print "r:$r";
    print "g:$g";
    print "b:$b";
    print "w:$w";
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $r/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $g/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $b/512*$brightness, 0x00, 0xAA, 0xAA));
    $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, $w/512*$brightness, 0x00, 0xAA, 0xAA));
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "R", $r);
    readingsBulkUpdate($Device, "G", $g);
    readingsBulkUpdate($Device, "B", $b);
    readingsBulkUpdate($Device, "W", $w);
    readingsBulkUpdate($Device, "RGB", substr($args[0], 0, 6));
    readingsBulkUpdate($Device, "RGBW", $args[0]);
	  readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'dim')
  {
    if($Device->{LEDTYPE} eq "RGBW")
    {
      my $rgbw = ReadingsVal($Device->{NAME}, "RGBW", undef);
      my $r = hex substr($rgbw, 0, 2);
  		my $g = hex substr($rgbw, 2, 2);
  		my $b = hex substr($rgbw, 4, 2);
  		my $w = hex substr($rgbw, 6, 2);
      $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $r/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $g/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $b/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, $w/512*$args[0], 0x00, 0xAA, 0xAA));
    }
    elsif($Device->{LEDTYPE} eq "CCT")
    {
      my $ww = ReadingsVal($Device->{NAME}, "WW", undef);
      my $cw = ReadingsVal($Device->{NAME}, "CW", undef);
      $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, $ww/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, $cw/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, $ww/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, $cw/512*$args[0], 0x00, 0xAA, 0xAA));
    }
    elsif($Device->{LEDTYPE} eq "DIM")
    {
      $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x18, 255/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x19, 255/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x20, 255/512*$args[0], 0x00, 0xAA, 0xAA));
      $msg .= LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x08, 0x21, 255/512*$args[0], 0x00, 0xAA, 0xAA));
    }
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "brightness", $args[0]);
    readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'dimup')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "brightness", $brightness+1);
    readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'dimdown')
  {
    my $brightness = ReadingsVal($Device->{NAME}, "brightness", undef);
    readingsBeginUpdate($Device);
    readingsBulkUpdate($Device, "brightness", $brightness-1);
    readingsEndUpdate($Device, 1);
  }
  elsif($cmd eq 'on')
  {
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x02, 0x12, 0xAB, 0x00, 0xAA, 0xAA ));
    $Device->{STATE} = "on";
  }
  elsif($cmd eq 'off')
  {
    $msg = LK35_Checksum($Device, pack('C*', 0x55, 0x00, 0x00, 0x00, 0x02, 0x00, 0x02, 0x12, 0xA9, 0x00, 0xAA, 0xAA ));
    $Device->{STATE} = "off";
  }


  #send package to controller
  LK35_send($Device, $msg);
}

sub
LK35_Get(@)
{

}

sub
LK35_send (@)
{
  my ($Device, $cmd) = @_;
  my $debug = unpack("H*", $cmd);
  # TCP
  Log3 ($Device, 4, "$Device->{NAME} send $debug,  connection refused: trying to reconnect");


  if (!$Device->{helper}->{SOCKET} || ($Device->{helper}->{SELECT}->can_read(0.0001) && !$Device->{helper}->{SOCKET}->recv(my $data, 512)))
  {
    Log3 ($Device, 4, "$Device->{NAME} send $debug, connection refused: trying to reconnect");

    $Device->{helper}->{SOCKET}->close() if $Device->{helper}->{SOCKET};

    $Device->{helper}->{SOCKET} = IO::Socket::INET-> new (
      PeerPort => $Device->{PORT},
      PeerAddr => $Device->{IP},
      Timeout => 1,
      Blocking => 0,
      Proto => 'tcp') or Log3 ($Device, 3, "$Device->{NAME} send ERROR $debug (reconnect giving up)");
    $Device->{helper}->{SELECT} = IO::Select->new($Device->{helper}->{SOCKET}) if $Device->{helper}->{SOCKET};
  }
  $Device->{helper}->{SOCKET}->send($cmd) if $Device->{helper}->{SOCKET};

  return undef;
}


sub
LK35_Checksum(@)
{
  my ($ledDevice, $msg) = @_;

  my @byteStream = unpack('C*', $msg);
  my $l = @byteStream;
  my $c = 0;

  for (my $i=4; $i<($l-3); $i++) {
    $c += $byteStream[$i];
  }
  $c %= 0x100;
  $byteStream[$l -3]  = $c;
  $msg = pack('C*', @byteStream);
  return $msg;
}

1;

=pod

=item summary controls the network-enabled power-outles of the NETIO_4x series via the JSON M2M API

=begin html

<a name="LK35"></a>
<h3>NETIO_4x</h3>
<ul>
    <i>NETIO_4x</i> provides communication with NETIO_4x devices via the JSON M2M API. The API needs to be turned on in the device settings prior to defining the device within FHEM.
    <br><br>
    <a name="LK35_Define"></a>
    <b>Define</b>
    <ul>
        <code>define &lt;name&gt; NETIO_4x &lt;model&gt; &lt;connection&gt;</code>
        <br><br>
        Example:<br/>
        <code>
          define Server_Rack NETIO_4x 4 http://192.168.1.10 <br/><br/>
          # define a '4All' device using a custom port<br/>
          define Server_Rack NETIO_4x 4All http://192.168.1.10:99 <br/><br/>
          # define a '4C' device using basicAuth on standard port <br/>
          define Server_Rack NETIO_4x 4C http://bob:123456@192.168.1.10 <br/><br/>
          # define a '4' device using basicAuth on custom port<br/>
          define Server_Rack NETIO_4x 4 http://bob:123456@192.168.1.10:123 <br/><br/>
        </code>
        <br><br>
        <code>&lt;name&gt;</code> can be any string describing the devices name within FHEM<br/>
        <code>&lt;model&gt;</code> can be one of the following device-models: <code>4</code>, <code>4C</code> or <code>4All</code><br/>
        <code>&lt;connection&gt;</code> can be provided with the following format: <code>http://user:password@HOST:PORT</code> <br/>
        <ul>
          <li><code>https</code> is not supported</li>
          <li><code>user:password@</code> may be ommited if no basicAuth is used</li>
          <li><code>HOST</code> may be supplied as an IPv4-address (i.e. <code>192.168.1.123</code>) or as hostname/domain (i.e. <code>mynetio.example.domain</code>)</li>
          <li>if <code>:PORT</code> is ommited, default port 80 is used</li>
        </ul>
    </ul>
    <br>

    <a name="LK35_Set"></a>
    <b>Set</b><br>
    <ul>
        <code>set &lt;name&gt; &lt;output&gt; &lt;command&gt;</code>
        <br><br>
        You can <i>set</i> an <code>&lt;output&gt;</code> (1-4) by submitting a <code>&lt;command&gt;</code> (0-6). All readings will be updated by the response of the device when they have changed (except the <b>OutputX_State</b> of the controlled outlet when the issued <code>&lt;command&gt;</code> was 2, 3, 5 or 6).
        <br><br>
        available <code>&lt;command&gt;</code> values:
        <ul>
              <li><code>0</code> - switch <code>&lt;output&gt;</code> off immediately</li>
              <li><code>1</code> - switch <code>&lt;output&gt;</code> on immediately</li>
              <li><code>2</code> - switch <code>&lt;output&gt;</code> off for the outputs <b>OutputX_Delay</b> reading (in ms) and then switch <code>&lt;output&gt;</code> on again (restart)</li>
              <li><code>3</code> - switch <code>&lt;output&gt;</code> on for the outputs <b>OutputX_Delay</b> reading (in ms) and then switch <code>&lt;output&gt;</code> off again</li>
              <li><code>4</code> - toggle <code>&lt;output&gt;</code> (invert the state)</li>
              <li><code>5</code> - no change on <code>&lt;output&gt;</code> (output state is retained)</li>
              <li><code>6</code> - ignore (state value is used to controll output) <b><i>!NOTE!</i></b> that no state value is send by the NETIO_4x module.</li>
        </ul>
    </ul>
    <br>

    <a name="LK35_Get"></a>
    <b>Get</b><br>
    <ul>
        <code>get &lt;name&gt; status</code>
        <br><br>
        You can <i>get</i> all the available info from the device and update the readings.
    </ul>
    <br>

    <a name="LK35_Readings"></a>
    <b>Readings</b><br>
    <ul>
      <ul>
            <li><b>OutputX_State</b> - state of each output (0=off, 1=on)</li>
            <li><b>OutputX_Delay</b> - the delay which is used for short off/on (<code>&lt;command&gt;</code> 2/3) in ms for each output</li>
      </ul><br/>
      Netio-Devices of the <code>&lt;model&gt; 4All</code> also submit the following readings:
      <ul>
            <li><b>OutputX_Current</b> - the current drawn from each outlet (in mA)</li>
            <li><b>OutputX_Energy</b> - the energy consumed by each outlet since the time given in the <b>EnergyStart</b> reading (in Wh)</li>
            <li><b>OutputX_Load</b> - the load on each outlet (in W)</li>
            <li><b>OutputX_PowerFactor</b> - the power-factor on each outlet</li>
            <li><b>EnergyStart</b> - date and time of the last reset of all energy counters</li>
            <li><b>Frequency</b> - AC frequency within the device (in Hz)</li>
            <li><b>OverallPowerFactor</b> - power-factor weighted average from all meters</li>
            <li><b>TotalCurrent</b> - the current drawn from all outlets (in mA)</li>
            <li><b>TotalEnergy</b> - the energy consumed on all outlets since the time given in the <b>EnergyStart</b> reading (in Wh)</li>
            <li><b>TotalLoad</b> - the load on all outlets (in W)</li>
            <li><b>Voltage</b> - AC voltage within the device (in V)</li>
      </ul>
    </ul>
</ul>

=end html

=cut
