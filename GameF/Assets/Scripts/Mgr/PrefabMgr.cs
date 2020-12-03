
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class PrefabMgr : MonoBehaviour
{
    private static string CardIconPth = "Image/Card/";
    private static string CardBorderPth = "Image/CardSP/";


    public static GameObject Load(string pth,Transform parent)
    {
        GameObject prefab = Resources.Load<GameObject>(pth);
        GameObject instance = Instantiate(prefab);
        instance.transform.parent = parent;
        instance.transform.position = parent.position;
        instance.transform.localScale = new Vector3(1, 1, 1) * 1f;
        return instance;
    }

    public static void SetIcon(GameObject obj, string pth) 
    {
        GameObject icon_ = GameObject.Find("Icon");
        Image icon = icon_.GetComponent<Image>();
        icon.sprite = Resources.Load(CardIconPth + pth, typeof(Sprite)) as Sprite;
    }
}
