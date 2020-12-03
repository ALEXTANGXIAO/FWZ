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
        Player = PrefabMgr.Load("Prefab/Item/CardItem", UIRoot.transform);
    }

    void Update()
    {
        
    }
}
