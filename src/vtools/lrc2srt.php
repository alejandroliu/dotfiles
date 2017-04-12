<?php
// http://www.lyricslrc.com/
define('CMD',basename(array_shift($argv),'.php'));

function usage() {
  die("Usage:\n\t".CMD." [--shift=seconds] file.lrc [...]\n\n");
}
function timecode($val) {
  $ms = (int)(($val - intval($val))*1000);
  $val = intval($val);
  return sprintf("%02d:%02d:%02d,%03d",$val / 3600, ($val/60)%60 , $val%60, $ms);
  
}
function timedecode($txt) {
  if (preg_match('/^(\d+):(\d+):(\d+),(\d+)$/',trim($txt),$mv)) {
    return (double)(((int)$mv[1])*3600+((int)$mv[2])*60+((int)$mv[3])) + ((double)((int)($mv[4])))/1000.0;
  }
  return 0.0;
}

if (count($argv) > 0) {
  if (substr($argv[0],0,8) == '--shift=') {
    $tshift = floatval(substr(array_shift($argv),8));
    fwrite(STDERR,"Will use $tshift offset\n");
  } else {
    $tshift = FALSE;
  }
}
if (count($argv) == 0) usage();

define('LRC_RE', '/\.lrc$/i');

$errs = 0;
foreach ($argv as $in) {
  if (!file_exists($in)) {
    fwrite(STDERR,"$in: not found\n");
    ++$errs;
    continue;
  }
  if (!preg_match(LRC_RE,$in)) {
    fwrite(STDERR,"$in: Not an LRC file\n");
    ++$errs;
    continue;
  }
  $output = preg_replace(LRC_RE,'.srt',$in);

  $get = file_get_contents($in); //read lrc file

  
  $whole = "";
  $i= preg_match_all("/\[(\d{2}:\d{2}\.\d{2})\](.*)/", $get, $out);
  if ($i == 0) {
    $i = preg_match_all("/\[(\d{2}:\d{2})\](.*)/", $get, $out);
    $out[0] = array_map(function ($n) {
	  list($a,$b) = explode(']',$n,2);
	  return $a.'.00]'.$b;
	},$out[0]);
    $out[1] = array_map(function ($n) { return $n.'.00'; },$out[1]);
    //print_r($out);
  }

  $srt = [];
  foreach ($out[0] as $row) {
    $tc = [];
    $offset = 0;
    while (preg_match("/\[(\d{2}:\d{2}\.\d{2})\]/",$row,$mv, PREG_OFFSET_CAPTURE, $offset)) {
      $offset = $mv[0][1]+strlen($mv[0][0]);
      $tc[] = $mv[1][0];
    }
    if (!count($tc)) continue;
    $txt = substr($row,$offset);
    foreach ($tc as $cc) {
      $cc = '00:'.str_replace('.',',',$cc).'0';
      if ($tshift) $cc = timecode(timedecode($cc)+$tshift);
      if (isset($srt[$cc])) {
	$srt[$cc] .= PHP_EOL.$txt;
      } else {
	$srt[$cc] = $txt;
      }
    }
  }
  ksort($srt);
  $end = [];
  $tc = FALSE;
  foreach (array_keys($srt) as $cc) {
    if ($tc) $end[$tc] = $cc;
    $tc = $cc;
  }
  $end[$tc] = $tc;

  $c = 0;
  $txt = '';
  foreach ($srt as $i=>$j) {
    $txt .= sprintf("%d",++$c).PHP_EOL;
    $txt .= $i.' --> '.$end[$i].PHP_EOL;
    $txt .= $j.PHP_EOL;
    $txt .= PHP_EOL;
  }
  file_put_contents($output, $txt);//write it
  fwrite(STDERR,"$in => $output\n");
}  
  
