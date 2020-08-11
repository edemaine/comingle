import React, {useRef} from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import FontAwesomeSVG from '@fortawesome/fontawesome-svg-core'
import {faTimes, faExpandArrowsAlt, faCompressArrowsAlt, faWindowRestore} \
  from '@fortawesome/free-solid-svg-icons'

export * from 'flexlayout-react'
import {Layout as FlexLayout} from 'flexlayout-react'

export Layout = (props) ->
  ref = useRef null
  onRenderTabSet = (node, renderState) ->
    {buttons} = renderState
    buttons.push <span ref={ref} key="ref"/>
    setTimeout ->
      if overflow = ref.current?.parentNode?.parentNode?.querySelector '.flexlayout__tab_button_overflow'
        svg = FontAwesomeSVG.icon(faWindowRestore).html[0]
        .replace /<svg/, '$& width="12px"'
        overflow.style.background = "no-repeat left url('data:image/svg+xml,#{svg}')"
    , 0
    props.onRenderTabSet? node, renderState
    return unless node.isEnableMaximize?()
    maxed = node.isMaximized()
    buttons.push \
      <button key="minmax" className="flexlayout__tab_toolbar_button-fa"
       title={if maxed then 'Unmaximize' else 'Maximize'}
       onClick={-> model.doAction FlexLayout.Actions.maximizeToggle node.getId()}>
        <FontAwesomeIcon icon={if maxed then faCompressArrowsAlt else faExpandArrowsAlt}/>
      </button>
  <FlexLayout {...props}
   closeIcon={<FontAwesomeIcon icon={faTimes}/>}
   onRenderTabSet={onRenderTabSet}
  />
