#!/usr/bin/perl
use strict;
use Audio::Wav;
use Math::Complex;
use GD;
use constant TWO_PI => pi() * 2;


my $wav = Audio::Wav->new();
my $sample_rate = 44100;
my $bits_sample = 16;


if( $#ARGV < 0 ) 
{
  print "Usage: $0 input_file <output_file>\n";
  exit 0;
}

# Start writing the wave with the proper arguments
write_out(( $#ARGV < 1) ? "$ARGV[0].wav" : $ARGV[1], $ARGV[0]);


sub write_out 
{
   # Set up the wave file
   my $filename = shift;
   my $write = $wav->write($filename, {
      bits_sample => $bits_sample,
      sample_rate => $sample_rate,
      channels    => 1,
   });

   # Set up the picture to read from
   my $imageName = shift;
   my $srcimage;
   open FILE, $imageName or die "Couldn't open: $imageName\n";
   close(FILE);
   my $ucImage = uc $imageName;
   if( $ucImage =~ m/.JPG/ || $ucImage =~ m/.JPEG/ )
   {
      $srcimage = GD::Image->newFromJpeg($imageName);
   } elsif ( $ucImage =~ m/.PNG/ ) {
      $srcimage = GD::Image->newFromPng($imageName);
   } elsif ( $ucImage =~ m/.GIF/ ) {
      $srcimage = GD::Image->newFromGif($imageName);
   } else {
      print "Unsupported filetype\nMust be png, jpg, jpeg, bmp, or gif\n";
      exit -1;
   }
   my ($srcW,$srcH) = $srcimage->getBounds();

   # Step through each pixel
   for( my $x = 0; $x < $srcW; $x ++ )
   {
      my @t = ();
      for( my $y = 0; $y < $srcH; $y ++ )
      {
         my $index = $srcimage->getPixel($x,$y);
         my ($r,$g,$b) = $srcimage->rgb($index);

         # Set the frequency and 'color' for this pixel.  Ignore if black
         if( $r > 10 || $g > 10 && $b > 10 )
         {
            my $c = 4.25 - 4.25*($r + $g + $b)/(256*3);
            push( @t, int(22000 - ( $y + 1)/( $srcH + 1) * 22000) );
            push( @t, $c );
         }
      }

      # Ugly way to show a status percentage
      my $status = int(100*$x/$srcW);
      my $statusDec = int(10000*$x/$srcW) - 100 * $status;
      print "\b\b\b\b\b\b\b\b\b\b\b\b$status.$statusDec%   ";
      $| = 1;

      # Add a .2 second set of sine waves
      add_sine($write, .2, @t);
   }

   # Finish up
   print "\b\b\b\b\b\b\b\b\b\b\b\b\b100%   \n";
   $write->finish();

}


sub add_sine {
   my ($write,$length,@freqs) = @_;
   my $max_no = (2 ** $bits_sample) / 2;
   $length *= $sample_rate;

   for my $pos (0..$length) {
       my $count = 0;
       my $val = 0;
       for( $count = 0; $count < @freqs.length; $count += 2)
       {
          my $time = ($pos / $sample_rate) * @freqs[$count];
          $val += sin(TWO_PI * $time)*10/(10 ** @freqs[$count + 1]); 
       }
       $val /= $count+1;
       my $samp = $val * $max_no;
       $write->write($samp);
   }
}
