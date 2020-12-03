using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameManager : MonoBehaviour
{
    public GameObject UIRoot;

    private GameObject Player;

    void Start()
    {
        for (int i = 1; i < 4; i++)
        {
            Player = PrefabMgr.Load("Prefab/Item/CardItem", UIRoot.transform);

            PrefabMgr.SetIcon(Player, "fwz_pic_mulinger");
        }
        
        //Player = PrefabMgr.Load("Prefab/Item/CardItem", UIRoot.transform);
    }

    void Update()
    {
        
    }
}
