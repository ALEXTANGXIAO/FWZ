
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PrefabMgr : MonoBehaviour
{


    public static GameObject Load(string pth,Transform parent)
    {
        GameObject prefab = Resources.Load<GameObject>(pth);
        GameObject instance = Instantiate(prefab);
        instance.transform.parent = parent;
        instance.transform.position = parent.position;
        instance.transform.localScale = new Vector3(1, 1, 1);
        return instance;
    }
}
