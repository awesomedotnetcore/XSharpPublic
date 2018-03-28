//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//
using System.Collections.Concurrent
using System.Collections.Generic
using System.Collections.Immutable
using System
using System.IO
begin namespace XSharpModel
	class SystemTypeController
		#region fields
		static private assemblies := ConcurrentDictionary<string, AssemblyInfo>{StringComparer.OrdinalIgnoreCase} as ConcurrentDictionary<string, XSharpModel.AssemblyInfo>
		static private _mscorlib := null as AssemblyInfo
		#endregion

		#region properties
		// Properties
		static property AssemblyFileNames as ImmutableList<string>
			get
				//
				return SystemTypeController.assemblies:Keys:ToImmutableList()
			end get
		end property
		
		static property MsCorLib as AssemblyInfo get _mscorlib set _mscorlib := value
		

		#endregion

		// Methods
		static method Clear() as void
			assemblies:Clear()
			_mscorlib := null
		
		static method FindAssemblyByLocation(location as string) as string
			if (assemblies:ContainsKey(location))
				return assemblies:Item[location]:FullName
			endif
			return null
		
		static method FindAssemblyByName(fullName as string) as string
			local info as AssemblyInfo
			foreach var pair in assemblies
				//
				info := pair:Value
				if (String.Compare(info:FullName, fullName, System.StringComparison.OrdinalIgnoreCase) == 0)
					//
					return info:FullName
				endif
			next
			return null
		
		static method FindAssemblyLocation(fullName as string) as string
			local info as AssemblyInfo
			//
			foreach var pair in assemblies
				//
				info := pair:Value
				if (! String.IsNullOrEmpty(info:FullName) .AND. (String.Compare(info:FullName, fullName, System.StringComparison.OrdinalIgnoreCase) == 0))
					//
					return pair:Key
				endif
			next
			return null
		
		method FindType(typeName as string, usings as IReadOnlyList<string>, assemblies as IReadOnlyList<AssemblyInfo>) as System.Type
			local strArray as string[]
			local num as long
			local index as long
			local str2 as string
			local str3 as string
			local num3 as long
			local strArray2 as string[]
			local type as System.Type
			//
			if (typeName:EndsWith(">"))
				//
				if (typeName:Length <= (typeName:Replace(">", ""):Length + 1))
					//
					strArray := typeName:Split("<,>":ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries)
					num := (strArray:Length - 1)
					typeName := strArray[ 1] + "`" + num:ToString()
				else
					//
					index := typeName:IndexOf("<")
					str2 := typeName:Substring(0, index)
					str3 := typeName:Substring((index + 1))
					str3 := str3:Substring(0, (str3:Length - 1)):Trim()
					index := str3:IndexOf("<")
					while index >= 0
						num3 := str3:LastIndexOf(">")
						str3 := str3:Substring(0, index) + str3:Substring((num3 + 1)):Trim()
						index := str3:IndexOf("<")
					enddo
					strArray2 := str3:Split(",":ToCharArray())
					typeName := str2 + "`" + strArray2:Length:ToString()
				endif
			endif
			type := Lookup(typeName, assemblies)
			if type != null
				return type
			endif
			if usings != null
				foreach strUsing as string in usings:Expanded()
					type := Lookup(strUsing + "." + typeName, assemblies)
					if type != null
						return type
					endif
				next
			endif
			if assemblies != null
				foreach var info in assemblies
					if (info:ImplicitNamespaces != null)
						foreach strNs as string in info:ImplicitNamespaces
							type := Lookup(strNs+  "."+  typeName, assemblies)
							if type != null
								return type
							endif
						next
					endif
				next
			endif
			type := Lookup("Functions." + typeName, assemblies)
			return type
		
		method GetNamespaces(assemblies as IList<AssemblyInfo>) as ImmutableList<string>
			var list := List<string>{}
			foreach var info in assemblies
				foreach str as string in info:Namespaces
					list:AddUnique( str)
				next
			next
			return System.Collections.Immutable.ImmutableList.ToImmutableList<string>(list)
		
		static method LoadAssembly(cFileName as string) as AssemblyInfo
			local info as AssemblyInfo
			local lastWriteTime as System.DateTime
			local key as string
			//
			lastWriteTime := File.GetLastWriteTime(cFileName)
			if (assemblies:ContainsKey(cFileName))
				info := assemblies:Item[cFileName]
			else
				info := AssemblyInfo{cFileName, System.DateTime.MinValue}
				assemblies:TryAdd(cFileName, info)
			endif
			if (cFileName:EndsWith("mscorlib.dll", System.StringComparison.OrdinalIgnoreCase))
				mscorlib := AssemblyInfo{cFileName, System.DateTime.MinValue}
			endif
			if (Path.GetFileName(cFileName):ToLower() == "system.dll")
				key := Path.Combine(Path.GetDirectoryName(cFileName), "mscorlib.dll")
				if (! assemblies:ContainsKey(key) .AND. File.Exists(key))
					LoadAssembly(key)
				endif
			endif
			return info
		
		static method LoadAssembly(reference as VsLangProj.Reference) as AssemblyInfo
			local path as string
			path := reference:Path
			if (String.IsNullOrEmpty(path))
				return AssemblyInfo{reference}
			endif
			return LoadAssembly(path)
		
		static method Lookup(typeName as string, theirassemblies as IReadOnlyList<AssemblyInfo>) as System.Type
			local type as System.Type
			type := null
			foreach var info in theirassemblies
				if (info:Types:Count == 0)
					info:UpdateAssembly()
				endif
				if (info:Types:TryGetValue(typeName, out type))
					exit
					
				endif
				if (info != null)
					type := info:GetType(typeName)
				endif
				if type != null
					exit
				endif
			next
			if type == null .AND. mscorlib != null
				type := mscorlib:GetType(typeName)
			endif
			return type
		
		static method RemoveAssembly(cFileName as string) as void
			local info as AssemblyInfo
			if assemblies:ContainsKey(cFileName)
				assemblies:TryRemove(cFileName, out info)
			endif
		
		static method UnloadUnusedAssemblies() as void
			local list as List<string>
			local info as AssemblyInfo
			list := List<string>{}
			foreach var pair in assemblies
				if ! pair:Value:HasProjects 
					list:Add(pair:Key)
				endif
			next
			foreach str as string in list
				assemblies:TryRemove(str, out info)
			next
			if (assemblies:Count == 0)
				mscorlib := null
			endif
			System.GC.Collect()
		
		
		
	end class
	
end namespace 

