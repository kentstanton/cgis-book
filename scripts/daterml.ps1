# daterml
# A DSL for managing data workflows



# script blocks have local scope, accept parameters, return values
$LoadFile = {
    param($onea,$twoa,$threea)

    $aa = "hello"

	$maths =  $SumMaker 
    #Write-Host "param one is $aa $two"	

	return "$aa $maths"


    SumMaker = {
	    $sum =  $one + $two + $three
    }

}



$ret = & $LoadFile -ArgumentList 1, 2,35467456746345234523452345
$ret