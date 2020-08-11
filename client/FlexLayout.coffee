import React from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTimes, faExpandArrowsAlt, faCompressArrowsAlt} from '@fortawesome/free-solid-svg-icons'

export * from 'flexlayout-react'
import {Layout as FlexLayout} from 'flexlayout-react'

export Layout = (props) ->
  onRenderTabSet = (node, renderState) ->
    props.onRenderTabSet? node, renderState
    return unless node.isEnableMaximize?()
    maxed = node.isMaximized()
    {buttons} = renderState
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
