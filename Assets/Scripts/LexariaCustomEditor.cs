using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;

public class LexariaCustomEditor : ShaderGUI
{
    private MaterialEditor editor;
    private Object[] materials;
    private MaterialProperty[] properties;
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        editor = materialEditor;
        materials = materialEditor.targets;
        this.properties = properties;
    }
}