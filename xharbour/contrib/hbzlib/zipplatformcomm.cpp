////////////////////////////////////////////////////////////////////////////////
// $Workfile: ZipPlatformComm.cpp $
// $Archive: /ZipArchive/ZipPlatformComm.cpp $
// $Date: 2003/08/20 15:03:53 $ $Author: lculik $
////////////////////////////////////////////////////////////////////////////////
// This source file is part of the ZipArchive library source distribution and
// is Copyright 2000-2003 by Tadeusz Dracz (http://www.artpol-software.com/)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// For the licensing details see the file License.txt
////////////////////////////////////////////////////////////////////////////////


#include "stdafx.h"
#include "zipplatform.h"

using namespace ZipPlatform;

bool ZipPlatform::DirectoryExists(LPCTSTR lpszDir)
{
	CZipString sz;
	if (!GetCurrentDirectory(sz))
		return false;
	if (!ChangeDirectory(lpszDir))
		return false;
	ChangeDirectory(sz);
	return true;
}

bool ZipPlatform::ForceDirectory(LPCTSTR lpDirectory)
{
	ASSERT(lpDirectory);
	CZipString szDirectory = lpDirectory;
	szDirectory.TrimRight(CZipPathComponent::m_cSeparator);
	CZipPathComponent zpc(szDirectory);
	if ((zpc.GetFilePath() == szDirectory) ||
		(FileExists(szDirectory) == -1))
		return true;
	if (!ForceDirectory(zpc.GetFilePath()))
		return false;
	if (!CreateDirectory(szDirectory))
		return false;
	return true;
}
