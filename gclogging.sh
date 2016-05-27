#!/bin/bash

acceptance_testing=""

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

	check_syntax_errors=`echo puppet parser validate $WORKSPACE/manifests/*.pp`
	$check_syntax_errors>check_syntax_errors.txt
	cat check_syntax_errors.txt

}


function check_code_quality(){
heading "[Starting] code quality check using puppet-lint tool"

	check_code_quality=`echo puppet-lint $WORKSPACE/project`
	$check_code_quality>check_code_quality.txt
	cat check_code_quality.txt
	if [ ! -s check_code_quality.txt ]; then
		check_code_quality="No errors"
	fi

}


function check_metadata_quality(){
heading "[Starting] Metadata quality check using metadata-json-lint tool"

	check_metadata_quality=`echo metadata-json-lint $WORKSPACE/project/metadata.json`
	$check_metadata_quality>check_metadata_quality.txt
	cat check_metadata_quality.txt	
	if [ ! -s check_metadata_quality.txt ]; then
		check_metadata_quality="No errors"
	fi
}


function acceptance_testing(){
heading "[Starting] Acceptance Testing using Beaker-rspec"
	pushd $WORKSPACE/project
		sudo bundle install 	
		sed --in-place '/log_level: verbose/d' "$WORKSPACE/project/spec/acceptance/nodesets/"*.yml
		for entry in "$WORKSPACE/spec/acceptance/nodesets"/*
		do
		  node_file=$(basename $entry)
		  filename="${node_file%.*}"
		  msg "OS: $filename"  	
		  result=`echo sudo BEAKER_set="${filename}" bundle exec rspec spec/acceptance`
		  $result>${filename}.txt
		  cat ${filename}.txt
		done
	popd
}

function result(){
heading "Result"

msg "1. Syntax errors : "
	
	if [ ! -s check_syntax_errors.txt ]; then
		echo "No syntax errors"
		PUPPET_COMPATIBILTY_CHEK_MAIL="<span class='success'>No syntax errors</span>"
	else
		cat check_syntax_errors.txt
		value=$(<check_syntax_errors.txt)
		PUPPET_COMPATIBILTY_CHEK_MAIL="<span class='error'>${value}</span>"
		
	fi


msg "2. Check code quality : "
	
		
	if [ ! -s check_code_quality.txt ]; then
		echo "No errors"
		PUPPET_CODE_QUALITY_CHEK_MAIL="<span class='success'>No errors</span>"
	else
		cat check_code_quality.txt
		value=$(<check_code_quality.txt)
		PUPPET_CODE_QUALITY_CHEK_MAIL="<span class='error'>${value}</span>"
	fi


msg "3. Check metadata quality : "

	
	if [ ! -s check_metadata_quality.txt ]; then
		echo "No errors"
		PUPPET_META_DATA_CHEK_MAIL="<span class='success'>No errors</span>"
	else
		cat check_metadata_quality.txt
		value=$(<check_metadata_quality.txt)
		PUPPET_META_DATA_CHEK_MAIL="<span class='error'>${value}</span>"
	fi


msg "4. Acceptance testing : "
	PUPPET_ACCEPTANCE_TESTING_MAIL=""
	for entry in "$WORKSPACE/project/spec/acceptance/nodesets"/*
	do
	  node_file=$(basename $entry)
	  filename="${node_file%.*}"
	  final_result=`grep --text -P '^[0-9]+ examples, [0-9]+ failures' ${filename}.txt`
	  echo "${filename}---------------${final_result}"
	  PUPPET_ACCEPTANCE_TESTING_MAIL="${PUPPET_ACCEPTANCE_TESTING_MAIL}<tr><td>${filename}</td><td>${final_result}</td></tr>"
	done
	echo $PUPPET_ACCEPTANCE_TESTING_MAIL

}


check_syntax_errors
check_code_quality
check_metadata_quality
acceptance_testing
result

eval "echo \"$(< puppet_report.html)\"" > $WORKSPACE/puppet_report.html




