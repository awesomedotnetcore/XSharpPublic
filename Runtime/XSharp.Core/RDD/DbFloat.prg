﻿//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//

/// <summary>Implementation of the IFloat interface that can be used by the RDD system. </summary> 
/// <seealso cref="T:XSharp.IFloat"/>
CLASS XSharp.RDD.DbFloat IMPLEMENTS IFLoat
	PROPERTY @@Value	AS REAL8 AUTO GET PRIVATE SET
	PROPERTY Digits		AS INT AUTO GET PRIVATE SET
	PROPERTY Decimals	AS INT AUTO GET PRIVATE SET
	CONSTRUCTOR(val AS REAL8, len AS INT, dec AS INT)
		VALUE := val
		Digits := len
		Decimals := dec
		
END	CLASS
		
/// <summary>Implementation of the IDate interface that can be used by the RDD system. </summary> 
/// <seealso cref="T:XSharp.IDate"/>
CLASS XSharp.RDD.DbDate IMPLEMENTS IDate
	PROPERTY Year		AS INT AUTO GET PRIVATE SET
	PROPERTY Month		AS INT AUTO GET PRIVATE SET
	PROPERTY Day		AS INT AUTO GET PRIVATE SET
	PROPERTY @@Value	AS DateTime GET DateTime{Year, Month, Day}
	PROPERTY IsEmpty	AS LOGIC GET Month != 0
	CONSTRUCTOR(nYear AS INT, nMonth AS INT, nDay AS INT)
		Year	:= nYear
		Month   := nMonth
		Day     := nDay
		RETURN
		
END CLASS