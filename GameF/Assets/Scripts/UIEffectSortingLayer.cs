using System.Collections.Generic;
using UnityEngine;

namespace DodGame
{
    public class UIEffectSortingLayer : MonoBehaviour
    {
        private Canvas m_cacheCanvas;

        public int m_sortOrder = 0;

        public void OnEnable()
        {
            ResetLayer();
        }

        public void Start()
        {
            ResetLayer();
        }

        public void ResetLayer()
        {
            if (m_cacheCanvas == null)
            {
                //m_cacheCanvas = transform.GetComponentInParent<Canvas>();
                var t = transform;
                while (t != null)
                {
                    m_cacheCanvas = t.GetComponent<Canvas>();
                    if (m_cacheCanvas != null) break;
                    t = t.parent;
                }
            }
            if (m_cacheCanvas == null)
            {
                return;
            }

            Renderer[] renderers = base.GetComponentsInChildren<Renderer>(true);
            for (int i = 0; i < renderers.Length; i++)
            {
                var render = renderers[i];
                render.sortingOrder = m_cacheCanvas.sortingOrder + m_sortOrder;
                var mats = render.materials;
                for (int j = 0; j < mats.Length; j++)
                {
                    var mat = mats[j];
                    if (mat != null && mat.shader != null)
                    {
                        /*
                        if (mat.renderQueue < 3000)
                        {
                            mat.renderQueue = 3000;
                        }
                        else if (mat.shader != null && mat.shader.renderQueue >= 3000 && mat.shader.name.Contains("Dodjoy/Actor/Show/"))
                        {
                            mat.renderQueue = mat.shader.renderQueue + 1;
                        }
                        */

                        var shaderName = mat.shader.name;
                        //如果是角色show系列的shader，特殊处理下
                        if (shaderName.Contains("Dodjoy/Actor/Show/"))
                        {
                            if (shaderName.Contains("Hair"))
                            {
                                mat.renderQueue = 3001;
                            }
                            else
                            {
                                mat.renderQueue = 3000;
                            }
                        }
                        else
                        {
                            //其余小于3000的，挂载到UI上统一放到3000
                            if (mat.renderQueue < 3000)
                            {
                                mat.renderQueue = 3000;
                            }
                        }
                    }
                }
            }
        }
    }
}