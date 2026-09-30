#pragma once
#include "shaders/VertexDeformation.h"
#include "shaders/VertexDeformationVertexLit.h"
#include "shaders/EllipsoidClip.h"
#include "shaders/EllipsoidClipVertexLit.h"

// Source shader internals are not exposed through a public API.
// This bridges into the material system using the layouts defined below.
#include "shadersystem.h"
// CShaderSystem exposes the internal shader DLL list through this compatibility
// layout so custom shaders can be registered without a public injection API.

// These externals must be valid before shaders are inserted.
extern IMaterialSystemHardwareConfig* g_pHardwareConfig = NULL;
extern const MaterialSystem_Config_t* g_pConfig = NULL;
IShaderSystem* g_pSLShaderSystem;

CShaderSystem::ShaderDLLInfo_t* shaderlibdll = NULL;	// our shader "directory"
//int m_ShaderDLLs_index;

#ifndef _LINUX
#define INTERFACE_MATERIALSYSTEM "materialsystem"
#else
#define INTERFACE_MATERIALSYSTEM "linux64/materialsystem_client"
#endif

// returns true if successful, false otherwise
bool inject_shaders() {
	// Load source interfaces for personal use
	if (!Sys_LoadInterface(INTERFACE_MATERIALSYSTEM, MATERIALSYSTEM_HARDWARECONFIG_INTERFACE_VERSION, NULL, (void**)&g_pHardwareConfig)) return false;
	if (!Sys_LoadInterface(INTERFACE_MATERIALSYSTEM, MATERIALSYSTEM_CONFIG_VERSION, NULL, (void**)&g_pConfig)) return false;
	if (!Sys_LoadInterface(INTERFACE_MATERIALSYSTEM, SHADERSYSTEM_INTERFACE_VERSION, NULL, (void**)&g_pSLShaderSystem)) return false;

	// The compiled shaders target DX9 and later.
	if (g_pHardwareConfig->GetDXSupportLevel() < 90) return false;

	// Cast the interface to the compatibility layout defined by shadersystem.h.
	CShaderSystem* s_ShaderSystem = (CShaderSystem*)g_pSLShaderSystem;

	// Reuse an existing shader DLL slot; custom entries are removed on eject.
	shaderlibdll = &s_ShaderSystem->m_ShaderDLLs[0];
	
	// Compiled .vcs files must exist in garrysmod/shaders/fxc.
	shaderlibdll->m_ShaderDict.Insert(VertexDeformation::s_Name, &VertexDeformation::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(VertexDeformationVertexLit::s_Name, &VertexDeformationVertexLit::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(EllipsoidClip::s_Name, &EllipsoidClip::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(EllipsoidClipVertexLit::s_Name, &EllipsoidClipVertexLit::s_ShaderInstance);
	
	return true;
}

bool eject_shaders() {
	// Registered shaders must be removed before the module unloads.
	if (shaderlibdll) {
		shaderlibdll->m_ShaderDict.Remove(VertexDeformation::s_Name);
		shaderlibdll->m_ShaderDict.Remove(VertexDeformationVertexLit::s_Name);
		shaderlibdll->m_ShaderDict.Remove(EllipsoidClip::s_Name);
		shaderlibdll->m_ShaderDict.Remove(EllipsoidClipVertexLit::s_Name);

		return true;
	}

	return false;
}
