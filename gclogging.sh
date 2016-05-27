#!/bin/bash
 
function heading(){
message=$1
echo " "
echo "======================================================================"
echo " ${message}"
echo "======================================================================"
echo " "

}

function msg(){
message=$1
echo " "
echo " ${message}"
echo " "
}

function msg(){
message=$1
echo " "
echo "[${message}]"
echo " "
}

function check_syntax_errors(){	
heading "[Starting] check syntax errors using puppet parser"

	check_syntax_errors=`echo puppet parser validate manifests/*.pp`
	$check_syntax_errors>check_syntax_errors.txt
	cat check_syntax_errors.txt

}


function check_code_quality(){
heading "[Starting] code quality check using puppet-lint tool"

	check_code_quality=`echo puppet-lint $WORKSPACE`
	$check_code_quality>check_code_quality.txt
	cat check_code_quality.txt
	if [ ! -s check_code_quality.txt ]; then
		check_code_quality="No errors"
	fi

}


function check_metadata_quality(){
heading "[Starting] Metadata quality check using metadata-json-lint tool"

	check_metadata_quality=`echo metadata-json-lint metadata.json`
	$check_metadata_quality>check_metadata_quality.txt
	cat check_metadata_quality.txt	
	if [ ! -s check_metadata_quality.txt ]; then
		check_metadata_quality="No errors"
	fi
}


function acceptance_testing(){
heading "[Starting] Acceptance Testing using Beaker-rspec"
acceptance_testing=""	
	sudo bundle install 	
	sed --in-place '/log_level: verbose/d' "$WORKSPACE/spec/acceptance/nodesets/"*.yml
	for entry in "$WORKSPACE/spec/acceptance/nodesets"/*
	do
	  node_file=$(basename $entry)
	  filename="${node_file%.*}"
	  msg "OS: $filename"  	
	  result=`echo sudo BEAKER_set="${filename}" bundle exec rspec spec/acceptance`
	  $result>${filename}.txt
	  cat ${filename}.txt
	  final_result=`grep --text -P '^[0-9]+ examples, [0-9]+ failures' ${filename}.txt`
	  echo $final_result
	  acceptance_testing="${acceptance_testing}${filename}      ${final_result}\n"
	done
}

function result(){
heading "Result"

msg "1. Syntax errors : "
	
	if [ ! -s check_syntax_errors.txt ]; then
		echo "No syntax errors"
	else
		cat check_syntax_errors.txt
	fi


msg "2. Check code quality : "
	
		
	if [ ! -s check_code_quality.txt ]; then
		echo "No errors"
	else
		cat check_code_quality.txt
	fi


msg "3. Check metadata quality : "

	
	if [ ! -s check_metadata_quality.txt ]; then
		echo "No errors"
	else
		cat check_metadata_quality.txt
	fi


msg "4. Acceptance testing : "

	printf $acceptance_testing

}

check_syntax_errors
check_code_quality
check_metadata_quality
acceptance_testing
result




