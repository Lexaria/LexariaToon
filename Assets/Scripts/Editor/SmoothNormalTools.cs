using System;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public enum WRITETYPE{
    VertexColor,
    Tangent
}
public class SmoothNormalTools : EditorWindow
{
    public WRITETYPE wt;
    public GameObject selectGameObject;

    [MenuItem("Tools/Normal Smooth Tool")]
    static void Init()
    {
        EditorWindow.GetWindow(typeof(SmoothNormalTools), true, "Smooth Normal Tool").Show();
    }

    private void OnGUI()
    {
        // Window Code
        EditorGUILayout.LabelField("1. Select the target object", EditorStyles.boldLabel);
        EditorGUILayout.LabelField("You've selected: ");
        GUILayout.Space(10);
        if (selectGameObject)
        {
            EditorGUILayout.LabelField(selectGameObject.name, EditorStyles.whiteBoldLabel);
        }
        GUILayout.Space(10);
        EditorGUILayout.LabelField("2. Select a target to write normal data to", EditorStyles.boldLabel);
        wt = (WRITETYPE)EditorGUILayout.EnumPopup("Target", wt);
        switch (wt)
        {
            case WRITETYPE.VertexColor:
                GUILayout.Label("The smoothed normal data will be saved as the mesh's vertex color");
                break;
            case WRITETYPE.Tangent:
                GUILayout.Label("The smoothed normal data will be saved as the mesh's tangents");
                break;
        }
        
        GUILayout.Space(10);
        GUILayout.Label("3. Execute",EditorStyles.boldLabel);
        GUILayout.Label("Mesh will be saved to Assets/SmoothNormalTool/");
        GUILayout.Space(10);
        if (GUILayout.Button("SMOOTH NORMAL"))
        {
            SmoothNormal();
        }
    }

    private void OnSelectionChange()
    {
        selectGameObject = Selection.activeGameObject;
    }

    void SmoothNormal()
    {
        if (selectGameObject)
        {
            MeshFilter[] meshFilters = selectGameObject.GetComponentsInChildren<MeshFilter>();
            SkinnedMeshRenderer[] skinMeshRenders = selectGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
            foreach (var meshFilter in meshFilters)
            {
                Mesh mesh = meshFilter.sharedMesh;
                Vector3 [] averageNormals = AverageNormals(mesh);
                ExportMesh(mesh,averageNormals);
            
            }
            foreach (var skinMeshRender in skinMeshRenders)
            {   
                Mesh mesh = skinMeshRender.sharedMesh;
                Vector3 [] averageNormals = AverageNormals(mesh);
                ExportMesh(mesh,averageNormals);
            } 
        }
        else
        {
            Debug.LogError("Please select a gameObject first!");
        }
        return;
    }

    Vector3[] AverageNormals(Mesh mesh)
    {
        var averageNormalHash = new Dictionary<Vector3, Vector3>();
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            if (!averageNormalHash.ContainsKey(mesh.vertices[i]))
            {
                averageNormalHash.Add(mesh.vertices[i], mesh.normals[i]);
            }
            else
            {
                averageNormalHash[mesh.vertices[i]] =
                    (averageNormalHash[mesh.vertices[i]] + mesh.normals[i]).normalized;
            }
        }

        Vector3[] averageNormals = new Vector3[mesh.vertexCount];
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            averageNormals[i] = averageNormalHash[mesh.vertices[i]];
        }

        return averageNormals;
    }

    void CopyMesh(Mesh meshDst, Mesh meshSrc)
    {
        // foreach (var property in typeof(Mesh).GetProperties())
        // {
        //     if (property.GetSetMethod() != null)
        //     {
        //         Debug.Log(property.Name + ": " + property.GetValue(meshSrc));
        //         property.SetValue(meshDst, property.GetValue(meshSrc));
        //     }
        // }
        meshDst.Clear();
        meshDst.vertices = meshSrc.vertices;

        List<Vector4> uvs = new List<Vector4>();
        meshSrc.GetUVs(0, uvs); meshDst.SetUVs(0, uvs);
        meshSrc.GetUVs(1, uvs); meshDst.SetUVs(1, uvs);
        meshSrc.GetUVs(2, uvs); meshDst.SetUVs(2, uvs);
        meshSrc.GetUVs(3, uvs); meshDst.SetUVs(3, uvs);
        meshDst.name = meshSrc.name ;
        meshDst.normals = meshSrc.normals;
        meshDst.tangents = meshSrc.tangents;
        meshDst.boneWeights = meshSrc.boneWeights;
        meshDst.colors = new Color[meshSrc.vertices.Length];
        meshDst.colors32 = new Color32[meshSrc.vertices.Length];
        meshDst.bindposes = meshSrc.bindposes;
        meshDst.indexFormat = meshSrc.indexFormat;
        meshDst.indexBufferTarget = meshSrc.indexBufferTarget;
        meshDst.vertexBufferTarget = meshSrc.vertexBufferTarget;
        meshDst.bounds = meshSrc.bounds;
        meshDst.triangles = meshSrc.triangles;
        meshDst.subMeshCount = meshSrc.subMeshCount;
        for (int i = 0; i < meshSrc.subMeshCount; i++)
            meshDst.SetIndices(meshSrc.GetIndices(i), meshSrc.GetTopology(i), i);
    }
    
    void ExportMesh(Mesh mesh, Vector3[] averageNormals)
    {
        Mesh meshNew = new Mesh();
        CopyMesh(meshNew, mesh);
        switch (wt)
        {
            case WRITETYPE.Tangent:
                Debug.Log("Saving to mesh's tangents");
                var tangents = new Vector4[meshNew.vertexCount];
                for (int i = 0; i < meshNew.vertexCount; i++)
                {
                    tangents[i] = new Vector4(averageNormals[i].x, averageNormals[i].y, averageNormals[i].z, 0);
                }
                meshNew.tangents = tangents;
                break;
            case WRITETYPE.VertexColor:
                Debug.Log("Saving to mesh's vertex color");
                Color[] _newColors = new Color[meshNew.vertexCount];
                Color[] _oldColors = new Color[meshNew.vertexCount];
                if (meshNew.colors.Length == 0)
                {
                    Debug.LogError("Vertex Color NULL!");
                }
                _oldColors = meshNew.colors;
                for (int i = 0; i < meshNew.vertexCount; i++)
                {
                    _newColors[i] = new Vector4(averageNormals[i].x, averageNormals[i].y, averageNormals[i].z, _oldColors[i].a);
                }
                meshNew.colors = _newColors;
                break;
        }

        string savePath = Application.dataPath + "/SmoothNormalTool";
        
        if (!Directory.Exists(savePath))
            Directory.CreateDirectory(savePath);
        
        AssetDatabase.Refresh();
        switch (wt)
        {
            case WRITETYPE.Tangent:
                meshNew.name = meshNew.name + "_SMNormal_Tangent";
                break;
            case WRITETYPE.VertexColor:
                meshNew.name = meshNew.name + "_SMNormal_VertexColor";
                break;
        }
        Debug.Log(savePath + "/" + meshNew.name);
        AssetDatabase.CreateAsset(meshNew, "Assets/SmoothNormalTool/" + meshNew.name + ".asset");
        Debug.Log("Saved Successfully");
    }
}


