#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::ASN1 qw(:all);

print "1..150\n";

BEGIN { require 't/funcs.pl' }

ntest 1, 129,      asn_tag(ASN_CONTEXT, 1);
ntest 2, 0x201f,   asn_tag(ASN_UNIVERSAL, 32);
ntest 3, 0x01825f, asn_tag(ASN_APPLICATION, 257);

stest 4, pack("C*", 129),            asn_encode_tag(129);
stest 5, pack("C*", 0x1f,0x20),      asn_encode_tag(0x201f);
stest 6, pack("C*", 0x5f,0x82,0x01), asn_encode_tag(0x01825f);

ntest 7, 129,       asn_decode_tag(asn_encode_tag(asn_tag(ASN_CONTEXT, 1)));
ntest 8, 0x201f,    asn_decode_tag(asn_encode_tag(asn_tag(ASN_UNIVERSAL, 32)));
ntest 9, 0x01825f,  asn_decode_tag(asn_encode_tag(asn_tag(ASN_APPLICATION, 257)));

ntest 10, 1, (asn_decode_tag(asn_encode_tag(asn_tag(ASN_CONTEXT, 1))))[0];
ntest 11, 2, (asn_decode_tag(asn_encode_tag(asn_tag(ASN_UNIVERSAL, 32))))[0];
ntest 12, 3, (asn_decode_tag(asn_encode_tag(asn_tag(ASN_APPLICATION, 257))))[0];

stest 13, pack("C*", 45),             asn_encode_length(45);
stest 14, pack("C*", 0x81,0x8b),      asn_encode_length(139);
stest 15, pack("C*", 0x82,0x12,0x34), asn_encode_length(0x1234);

ntest 16, 45,     asn_decode_length(asn_encode_length(45));
ntest 17, 139,    asn_decode_length(asn_encode_length(139));
ntest 18, 0x1234, asn_decode_length(asn_encode_length(0x1234));

ntest 19, 1, (asn_decode_length(asn_encode_length(45)))[0];
ntest 20, 2, (asn_decode_length(asn_encode_length(139)))[0];
ntest 21, 3, (asn_decode_length(asn_encode_length(0x1234)))[0];

btest 22, $asn = Convert::ASN1->new;

##
## NULL
##

print "# NULL\n";

$buf = pack("C*", 0x05, 0x00);
btest 23, $asn->prepare(' null NULL ');
stest 24, $buf, $asn->encode(null => 1) or warn $asn->error;
btest 25, $ret = $asn->decode($buf) or warn $asn->error;
btest 26, $ret->{'null'};

##
## BOOLEAN 
##

$test = 27;

foreach $val (0,1,-99) {
  print "# BOOLEAN $val\n";

  my $result = pack("C*", 0x01, 0x01, $val ? 0xFF : 0);

  btest $test++, $asn->prepare(' bool BOOLEAN');
  stest $test++, $result, $asn->encode(bool => $val);
  btest $test++, $ret = $asn->decode($result);
  ntest $test++, !!$val, !!$ret->{'bool'};
}

##
## INTEGER (tests 13 - 21)
##

my %INTEGER = (
  pack("C*", 0x02, 0x02, 0x00, 0x80), 	      128,
  pack("C*", 0x02, 0x01, 0x80), 	      -128,
  pack("C*", 0x02, 0x02, 0xff, 0x01), 	      -255,
  pack("C*", 0x02, 0x01, 0x00), 	      0,
  pack("C*", 0x02, 0x03, 0x66, 0x77, 0x99),   0x667799,
  pack("C*", 0x02, 0x02, 0xFE, 0x37),	     -457,
  pack("C*", 0x02, 0x04, 0x40, 0x00, 0x00, 0x00),	     2**30,
  pack("C*", 0x02, 0x04, 0xC0, 0x00, 0x00, 0x00),	     -2**30,
);

while(($result,$val) = each %INTEGER) {
  print "# INTEGER $val\n";

  btest $test++, $asn->prepare(' integer INTEGER');
  stest $test++, $result, $asn->encode(integer => $val);
  btest $test++, $ret = $asn->decode($result);
  ntest $test++, $val, $ret->{integer};

}

btest $test++, $asn->prepare('test ::= INTEGER ');

$result = pack("C*", 0x02, 0x01, 0x09);

stest $test++, $result, $asn->encode(9);
btest $test++, $ret = $asn->decode($result);
btest $test++, $ret == 9;

##
## STRING
##

my %STRING = (
  pack("C*",   0x04, 0x00),		  "",
  pack("CCa*", 0x04, 0x08, "A string"),   "A string",
);

while(($result,$val) = each %STRING) {
  print "# STRING '$val'\n";

  btest $test++, $asn->prepare('str STRING');
  stest $test++, $result, $asn->encode(str => $val);
  btest $test++, $ret = $asn->decode($result);
  stest $test++, $val, $ret->{'str'};
}

##
## OBJECT_ID
##

my %OBJECT_ID = (
  pack("C*", 0x06, 0x04, 0x2A, 0x03, 0x04, 0x05), "1.2.3.4.5",
  pack("C*", 0x06, 0x03, 0x55, 0x83, 0x49),       "2.5.457",  
);


while(($result,$val) = each %OBJECT_ID) {
  print "# OBJECT_ID $val\n";

  btest $test++, $asn->prepare('oid OBJECT IDENTIFIER');
  stest $test++, $result, $asn->encode(oid => $val);
  btest $test++, $ret = $asn->decode($result);
  stest $test++, $val, $ret->{'oid'};
}

##
## ENUM
##

my %ENUM = (
  pack("C*", 0x0A, 0x01, 0x00),             0,	     
  pack("C*", 0x0A, 0x01, 0x9D),            -99,	     
  pack("C*", 0x0A, 0x03, 0x64, 0x4D, 0x90), 6573456,
);

while(($result,$val) = each %ENUM) {
  print "# ENUM $val\n";

  btest $test++, $asn->prepare('enum ENUMERATED');
  stest $test++, $result, $asn->encode(enum => $val);
  btest $test++, $ret = $asn->decode($result);
  ntest $test++, $val, $ret->{'enum'};
}

##
## BIT STRING
##

my %BSTR = (
  pack("C*", 0x03, 0x02, 0x07, 0x00),
    [pack("B*",'0'), 1, pack("B*",'0')],

  pack("C*", 0x03, 0x02, 0x00, 0x33),
    pack("B*",'00110011'),

  pack("C*", 0x03, 0x04, 0x03, 0x6E, 0x5D, 0xC0),
    [pack("B*",'011011100101110111'), 21, pack("B*",'011011100101110111')],

  pack("C*", 0x03, 0x02, 0x01, 0x6E),
    [pack("B*",'011011111101110111'), 7, pack("B*", '01101110')]
);

while(($result,$val) = each %BSTR) {
    print "# BIT STRING ", unpack("B*", ref($val) ? $val->[0] : $val),
	" ",(ref($val) ? $val->[1] : $val),"\n";

  btest $test++, $asn->prepare('bit BIT STRING');
  stest $test++, $result, $asn->encode( bit => $val);
  btest $test++, $ret = $asn->decode($result);
  stest $test++, (ref($val) ? $val->[2] : $val), $ret->{'bit'}[0];
  ntest $test++, (ref($val) ? $val->[1] : 8*length$val), $ret->{'bit'}[1];

}

##
## REAL
##

use POSIX qw(HUGE_VAL);

my %REAL = (
  pack("C*", 0x09, 0x00),  0,
  pack("C*", 0x09, 0x03, 0x80, 0xf9, 0xc0),  1.5,
  pack("C*", 0x09, 0x03, 0xc0, 0xfb, 0xb0), -5.5,
  pack("C*", 0x09, 0x01, 0x40),		      HUGE_VAL(),
  pack("C*", 0x09, 0x01, 0x41),		    - HUGE_VAL(),
);

while(($result,$val) = each %REAL) {
  print "# REAL $val\n";
  btest $test++, $asn->prepare('real REAL');
  stest $test++, $result, $asn->encode( real => $val);
  btest $test++, $ret = $asn->decode($result);
  ntest $test++, $val, $ret->{'real'};
}

##
## RELATIVE-OID
##

my %ROID = (
  pack("C*", 0x0D, 0x05, 0x01, 0x02, 0x03, 0x04, 0x05), "1.2.3.4.5",
  pack("C*", 0x0D, 0x04, 0x02, 0x05, 0x83, 0x49),       "2.5.457",  
);


while(($result,$val) = each %ROID) {
  print "# RELATIVE-OID $val\n";

  btest $test++, $asn->prepare('roid RELATIVE-OID');
  stest $test++, $result, $asn->encode(roid => $val);
  btest $test++, $ret = $asn->decode($result);
  stest $test++, $val, $ret->{'roid'};
}

