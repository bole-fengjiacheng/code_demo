selfConfig = {}

local customStr = "custome" --自定义log标识
local script_server = bole.resourceServer
selfConfig.resourceServer = nil
selfConfig.debugMode = true

selfConfig.serverIp = "123.56.7.6"
selfConfig.serverPort = 1240
selfConfig.skipLoginPopUp = false
selfConfig.showDiffCoins = true --主题内footer中间增加显示前后端blance的按钮

-- local toThemeId = 30174 --跳过大厅直接进入主题id
local accessId = {} --用户id判断，空表为都可以直接进入

selfConfig.getDirectToTheme = function ()
    local saveThemeId = cc.UserDefault:getInstance():getIntegerForKey('debug_quick_entry_theme', -1)
    saveThemeId = (saveThemeId ~= -1) and saveThemeId or nil

    local themeId = saveThemeId or toThemeId
    local isQuickEntry = cc.UserDefault:getInstance():getBoolForKey('debug_can_quick_entry_theme', true)
    if not isQuickEntry then return 'cant quick entry' end

    local accessIdSet = Set(accessId)
    local userId = User:getInstance().user_id
    if not table.empty(accessId) and not accessIdSet[userId] then return 'not access user' end

    return themeId
end


local sendToSever = function(title, content)
    content = content:gsub('"', '\"')
    content = content:gsub("\'", '\"')
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xhr:open("POST", "http://192.168.0.208/Logs/recv.php")
    xhr:setRequestHeader("Content-Type", "application/json")
    xhr:send(json.encode({[title] = content}))
end

selfConfig.logCached = {"--- LOG_START ---"}
selfConfig.sendLog = function(content)
    if User and bole.potp and User.__inst and User.__inst.user_id then
        content = string.sub(content, 1, -2)
        local dayStr = os.date("%Y%m%d")
        local timeStr = os.date("%H:%M:%S")
        if selfConfig.logFlag == timeStr then
            table.insert(selfConfig.logCached, content)
        else
            local fn = dayStr.."-"..User:getInstance().user_id.."-"..customStr
            sendToSever(fn, table.concat(selfConfig.logCached, ";"))
            selfConfig.logFlag = timeStr
            selfConfig.logCached = {"\n[time "..timeStr.."]"..content}
        end
    end
end
-- selfConfig.sendLog = nil  --因log发送频繁数据多，默认关闭

selfConfig.sendError = function(content)
    local dayStr = os.date("%Y%m%d")
    local timeStr = os.date("%H:%M:%S").."  script_server:"..script_server
    local str = selfConfig.errorFlag == timeStr and content or "\n---time:"..timeStr.."---\n"..content
    local fn = "Errors-"..customStr.."-"..dayStr
    sendToSever(fn, str)
    selfConfig.errorFlag = timeStr
end


selfConfig.tableToStr = function (t)
    if t == nil then return "" end
    local function toStringEx(value)
        if type(value)=='table' then
            return selfConfig.tableToStr(value)
        elseif type(value)=='string' then
            return "\'"..value.."\'"
        else
        return tostring(value)
        end
    end
    local retstr= "{"
    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
          signal = ""
        end

        if key == i then
            retstr = retstr..signal..toStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..toStringEx(key).."]="..toStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..toStringEx(value)
                else
                    retstr = retstr..signal..key.."="..toStringEx(value)
                end
            end
        end

        i = i+1
    end
     retstr = retstr.."}"
     return retstr
end

selfConfig.printSocketLog = function(data, isRecv)
    if not isRecv then
        local str = selfConfig.tableToStr(data)
        log.i("===========send==========[#"..#str.."]", selfConfig.tableToStr(data))
    else
        local str = selfConfig.tableToStr(data)
        if #str <= 1000 then
            log.i("===========recv==========[#"..#str.."]", str)
        else
            local x = math.floor(#str/1000)
            local arr = {}
            log.i("===========recv==========[#"..#str.."]")
            for i=1,x+1 do
                arr[i] = string.sub(str,1000*(i-1),1000*i-1)
                log.i("part"..i..":",arr[i])
            end
        end
    end
end

selfConfig.serverChooser = function(callback)
    local serverIp
    local serverPort
    local tableView
    local isSelected
    local time = os.time() + 10 -- 倒计时时长

    local myLayer = cc.Layer:create()
    myLayer:setAnchorPoint(cc.p(0.5,0.5))
    myLayer:setScale(1)
    local myBg = cc.LayerColor:create(cc.c4b(0, 0, 0, 210), 800, 450)
    myBg:setAnchorPoint(cc.p(0.5,0.5))
    myLayer:addChild(myBg, 1)

    isSelected = cc.UserDefault:getInstance():getBoolForKey("isShowServerSelector")
    serverIp = cc.UserDefault:getInstance():getStringForKey("DebugToolServer")
    serverPort = cc.UserDefault:getInstance():getStringForKey("DebugToolPort")
    local lastServerLabel = cc.Label:create()
    lastServerLabel:setPosition(cc.p(400, 110)) -- 400, 110
    lastServerLabel:setColor(cc.c3b(0,255,0))
    if serverPort == "" or serverIp == "" then
        serverIp = selfConfig.serverIp
        serverPort = selfConfig.serverPort
    end
    if #serverIp > 30 then
        lastServerLabel:setString("selected server:  ".."正式服"..":"..serverPort)
    else
        lastServerLabel:setString("selected server:  "..serverIp..":"..serverPort)
    end
    lastServerLabel:setScale(2)
    myLayer:addChild(lastServerLabel, 1)

    local function freshLabel(node)
        local s = isSelected and "当前选择：跳过此界面" or "当前选择：不跳过此界面"
        node:setString(s)
        node:setBlendFunc(gl.ONE, gl.ZERO)
    end
    local showLabel = cc.Label:create()
    showLabel:setPosition(cc.p(650, 400)) -- 600, 70
    bole.addClickEvent(showLabel, function()
        isSelected = not isSelected
        freshLabel(showLabel)
    end)
    freshLabel(showLabel)
    myLayer:addChild(showLabel, 1)
    local infoLabel = cc.Label:create()
    infoLabel:setPosition(cc.p(650, 370)) -- 600, 40
    infoLabel:setString("选择跳过此界面后，需清缓存\n才可以重进选择服务器界面！")
    myLayer:addChild(infoLabel, 1)
    
    local cdLabel = cc.Label:create()

    local idRoot = cc.Node:create()
    myLayer:addChild(idRoot, 1)
    local label = cc.Label:create()
    label:setPosition(cc.p(610, 280))
    label:setString("指定的登录ID为：")
    idRoot:addChild(label, 1)
    local bianji = ccui.TextField:create()
    local defaultId = cc.UserDefault:getInstance():getStringForKey("DebugToolID")
    local function textFieldEvent(sender, eventType)
        local str = sender:getString()
        if eventType == ccui.TextFiledEventType.detach_with_ime then
            bianji:setString(str)
        elseif eventType == ccui.TextFiledEventType.insert_text then
            bianji:setString(str)
        elseif eventType == ccui.TextFiledEventType.attach_with_ime then
            bianji:setString("")
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            bianji:setString(str)
        end
        defaultId = str
    end
    bianji:addEventListener(textFieldEvent)
    bianji:setAnchorPoint(cc.p(0, 0.5))
    idRoot:addChild(bianji, 1)
    bianji:setPosition(cc.p(655, 280))
    bianji:setScale(0.7)
    bianji:setPlaceHolder(tonumber(defaultId) and defaultId or "输入你的id")
    local label = cc.Label:create()
    label:setPosition(cc.p(620, 300)) -- 600, 40
    label:setString("是否启用指定ID登录：")
    myLayer:addChild(label, 1)
    local checkLbl = cc.Label:create()
    myLayer:addChild(checkLbl, 1)
    checkLbl:setPosition(cc.p(685, 300)) -- 600, 40
    checkLbl:setColor(cc.c3b(255,0,0))
    checkLbl:setBlendFunc(gl.ONE, gl.ZERO)
    local isAssignId = cc.UserDefault:getInstance():getBoolForKey("selfConfig_isAssignId")
    checkLbl:setString(isAssignId and "是" or "否")
    idRoot:setVisible(isAssignId)
    bole.addClickEvent(checkLbl, function()
        isAssignId = not isAssignId
        idRoot:setVisible(isAssignId)
        cc.UserDefault:getInstance():setBoolForKey("selfConfig_isAssignId", isAssignId)
        checkLbl:setString(isAssignId and "是" or "否")
    end)

    local label = cc.Label:create()
    label:setPosition(cc.p(620, 240)) -- 600, 40
    label:setString("是否跳过登录弹窗：")
    myLayer:addChild(label, 1)
    local skipLbl = cc.Label:create()
    myLayer:addChild(skipLbl, 1)
    skipLbl:setPosition(cc.p(685, 240)) -- 600, 40
    skipLbl:setColor(cc.c3b(255,0,0))
    skipLbl:setBlendFunc(gl.ONE, gl.ZERO)
    selfConfig.skipLoginPopUp = cc.UserDefault:getInstance():getBoolForKey("selfConfig_skipLoginPopUp", false)
    skipLbl:setString(selfConfig.skipLoginPopUp and "是" or "否")
    bole.addClickEvent(skipLbl, function()
        selfConfig.skipLoginPopUp = not selfConfig.skipLoginPopUp
        cc.UserDefault:getInstance():setBoolForKey("selfConfig_skipLoginPopUp", selfConfig.skipLoginPopUp)
        skipLbl:setString(selfConfig.skipLoginPopUp and "是" or "否")
    end)

    selfConfig.addAssignSaleDate(myLayer)
    selfConfig.addActTimeCtl(myLayer)

    local enterFunc = function ()
        log.d("jhdbjasdd", isAssignId, defaultId)
        if isAssignId then
            local id = defaultId
            if tonumber(id) then
                cc.UserDefault:getInstance():setStringForKey("DebugToolID", id)
                DebugTool:getInstance():setUserId(tonumber(id))
            end
        end
        myLayer:removeFromParent()
        myLayer = nil
        cc.UserDefault:getInstance():setBoolForKey("isShowServerSelector", isSelected)
        cc.UserDefault:getInstance():setStringForKey("DebugToolServer", serverIp)
        cc.UserDefault:getInstance():setStringForKey("DebugToolPort", serverPort)
        _ = callback and callback(serverIp, serverPort)
    end


    local okLabel = cc.Label:create()
    okLabel:setPosition(cc.p(400, 50)) 
    okLabel:setScale(4)
    okLabel:setString("ok")
    okLabel:setColor(cc.c3b(255,0,0))
    -- okLabel:setBlendFunc(gl.ONE, gl.ZERO)
    bole.addClickEvent(okLabel, enterFunc)
    myLayer:addChild(okLabel, 1)

    cdLabel:setPosition(cc.p(100, 70))
    cdLabel:setScale(2)
    cdLabel:setBlendFunc(gl.ONE, gl.ZERO)
    bole.configCountDownLabel(cdLabel,
        function()
            return time - os.time()
        end,
        enterFunc)
    myLayer:addChild(cdLabel, 1)

    if tableView then 
        tableView:reloadData()
    else
        local function doHandle(node, idx)
            if #selfConfig.serverList[idx + 1].Ip > 30 then
                node:setString(selfConfig.serverList[idx + 1].Name..":    "..selfConfig.serverList[idx + 1].Name .. ":" .. selfConfig.serverList[idx + 1].Port)
            else
                node:setString(selfConfig.serverList[idx + 1].Name..":    "..selfConfig.serverList[idx + 1].Ip .. ":" .. selfConfig.serverList[idx + 1].Port)
            end
            bole.addClickEvent(node, function()
                local ip = selfConfig.serverList[idx + 1].Ip or "192.168.0.40"
                local port = selfConfig.serverList[idx + 1].Port or 1277
                lastServerLabel:setColor(cc.c3b(0,255,0))
                if #ip >30 then 
                    lastServerLabel:setString("selected server:  "..selfConfig.serverList[idx + 1].Name..":"..port)
                else
                    lastServerLabel:setString("selected server:  "..ip..":"..port)
                end
                serverIp, serverPort = ip, port
            end)
        end
        local function tableCellAtIndex(table, idx)
            local cell = table:dequeueCell()
            if nil == cell then
                cell = cc.TableViewCell:new()
                local label = cc.Label:create()
                label:setName("ranking_cell_panel")
                label:setPosition(cc.p(400, 10))
                label:setScale(1.5)
                label:setBlendFunc(gl.ONE, gl.ZERO)
                doHandle(label, idx)
                cell:addChild(label)
            else
                local label = cell:getChildByName("ranking_cell_panel")
                label:removeClickEvent()
                doHandle(label, idx)
                okLabel:stopAllActions()
                okLabel:setString("ok")
            end
            return cell
        end
        local function numberOfCellsInTableView(table)
            return #selfConfig.serverList
        end
        local function cellSizeForTable(table,idx)
            return 35
        end
        local function scrollViewDidScroll(view)
            -- log.d("did scroll") -- 初始化的时候调用了两次？？？？
        end
        local function scrollViewDidZoom(view)
            log.d("did zoom") -- 没找到调用的时刻
        end
        local function tableCellTouched(table,cell)
            log.d("cell touched at index: "..cell:getIdx())
            -- cell:getIdx()来获取cell的index值
        end
    
        tableView = cc.TableView:create(cc.size(800, 280))

        if bole.isValidNode(tableView) then
            tableView.isScrollView = 1
        end
        tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
        tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
        tableView:setDelegate()
        tableView:setPosition(cc.p(0, 150))
        myLayer:addChild(tableView, 500)
        tableView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  
        tableView:registerScriptHandler(scrollViewDidScroll,cc.SCROLLVIEW_SCRIPT_SCROLL)
        tableView:registerScriptHandler(scrollViewDidZoom,cc.SCROLLVIEW_SCRIPT_ZOOM)
        tableView:registerScriptHandler(cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
        tableView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
        tableView:registerScriptHandler(tableCellTouched, cc.TABLECELL_TOUCHED)
        tableView:reloadData()
    end
    -- selfConfig.salePromotionChoose(myLayer)

    if isSelected then 
        myLayer:removeFromParent()
        myLayer = nil
        cc.UserDefault:getInstance():setBoolForKey("isShowServerSelector", isSelected)
        cc.UserDefault:getInstance():setStringForKey("DebugToolServer", serverIp)
        cc.UserDefault:getInstance():setStringForKey("DebugToolPort", serverPort)
        _ = callback and callback(serverIp, serverPort)
    else
        bole.scene:addChild(myLayer, 999)
    end


    local clickLayer = cc.Layer:create()
    local function onTouchBegan( touch, event )
        return true
    end
    local function onTouchEnded(touch, event)
        if bole.isValidNode(cdLabel) then
            cdLabel:removeFromParent()
        end
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = clickLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, clickLayer)
    bole.scene:addChild(clickLayer, 1000)
end

local createLabel = function (str)
    local label = cc.Label:create()
    label:setString(str)
    return label
end

selfConfig.getAssignSaleDate = function()
    if selfConfig.assignSaleDate then
        return selfConfig.assignSaleDateStr
    end
end
selfConfig.addAssignSaleDate = function(myLayer)
    local idRoot = cc.Node:create()
    myLayer:addChild(idRoot, 2)
    local root1 = cc.Node:create()
    idRoot:addChild(root1, 1)

    local label = cc.Label:create()
    label:setPosition(cc.p(100, 300))
    label:setString("是否指定促销日期:")
    idRoot:addChild(label, 1)
    local skipLbl = cc.Label:create()
    myLayer:addChild(skipLbl, 1)
    skipLbl:setPosition(cc.p(160, 300)) -- 600, 40
    skipLbl:setColor(cc.c3b(255,0,0))
    skipLbl:setBlendFunc(gl.ONE, gl.ZERO)
    selfConfig.assignSaleDate = cc.UserDefault:getInstance():getBoolForKey("selfConfig_assignSaleDate", false)
    skipLbl:setString(selfConfig.assignSaleDate and "是" or "否")
    bole.addClickEvent(skipLbl, function()
        selfConfig.assignSaleDate = not selfConfig.assignSaleDate
        cc.UserDefault:getInstance():setBoolForKey("selfConfig_assignSaleDate", selfConfig.assignSaleDate)
        skipLbl:setString(selfConfig.assignSaleDate and "是" or "否")
        root1:setVisible(selfConfig.assignSaleDate)
    end)
    root1:setVisible(selfConfig.assignSaleDate)

    local lblDate = cc.Label:create()
    lblDate:setPosition(cc.p(120, 250))
    lblDate:setScale(2)
    root1:addChild(lblDate, 1)
    local label = cc.Label:create()
    label:setPosition(cc.p(120, 225))
    label:setString("(↑ 滑动修改 ↑)")
    root1:addChild(label, 1)
    local lastSaleDate = os.date("%Y-%m-%d", os.time() + cc.UserDefault:getInstance():getIntegerForKey("selfConfig_dateDiff"..os.date("%Y-%m-%d", os.time()), 0)*86400)
    selfConfig.assignSaleDateChange = false
    local changeDate = function (diff)
        diff = diff or 0
        local dayDiff = cc.UserDefault:getInstance():getIntegerForKey("selfConfig_dateDiff"..os.date("%Y-%m-%d", os.time()), 0)

        if diff ~= 0  then
            dayDiff = dayDiff + diff
            cc.UserDefault:getInstance():setIntegerForKey("selfConfig_dateDiff"..os.date("%Y-%m-%d", os.time()), dayDiff)
        end

        local dateStr = os.date("%Y-%m-%d", os.time() + dayDiff*86400)
        lblDate:setString(dateStr)
        selfConfig.assignSaleDateStr = dateStr
        selfConfig.assignSaleDateChange = dateStr ~= lastSaleDate
    end
    changeDate()

    local posStart = 0
	local function  onTouchBegan( touch, event )
		if bole.isTouchInPanel(lblDate, touch) then
			posStart = touch:getLocation().y
			return true
		end
	end

	local function onTouchEnd( touch,event )
		local pos = touch:getLocation().y
        local dis = math.abs(posStart - pos)
        if dis > 8 then
            changeDate(posStart > pos and 1 or -1)
        end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchEnd,cc.Handler.EVENT_TOUCH_ENDED )
    listener:setSwallowTouches(true)
    local eventDispatcher = lblDate:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, lblDate)
end

--START控制活动（完全前端控制）的当前时间
selfConfig.addActTimeCtl = function(myLayer)
    local priRoot = cc.Node:create()
    myLayer:addChild(priRoot, 2)
    local textNode = cc.Label:create()
    local checkNode =  cc.Label:create()
    textNode:setString("是否指定活动日期: ")
    textNode:setPosition(cc.p(100, 350))
    checkNode:setPosition(cc.p(200, 350))
    checkNode:setColor(cc.c3b(255,0,0))

    selfConfig.assignActDate = cc.UserDefault:getInstance():getBoolForKey("selfConfig_assignActDate", false)
    checkNode:setString(selfConfig.assignActDate and "是" or "否")
    bole.addClickEvent(checkNode, function()
        selfConfig.assignActDate = not selfConfig.assignActDate
        checkNode:setString(selfConfig.assignActDate and "是" or "否")
        local parent = priRoot:getParent():getParent()
        if bole.isValidNode(parent) then
            local cdNode = parent:getChildByName("cdLabel")
            _ = bole.isValidNode(cdNode) and cdNode:removeFromParent()
        end

        if selfConfig.assignActDate then
            selfConfig.createActLayer(myLayer)
            selfConfig.createActScrollView()
            selfConfig.addInfoInScroll()
        end
    end)

    priRoot:addChild(textNode)
    priRoot:addChild(checkNode)
    checkNode:setBlendFunc(gl.ONE, gl.ZERO)
    checkNode:setScale(1.4)
end

selfConfig.createActLayer = function(myLayer)
    local newLayer = cc.Layer:create()
    local myBg = cc.LayerColor:create(cc.c4b(0, 0, 0, 210), 800, 450)
    newLayer:addChild(myBg, 1)
    myLayer:addChild(newLayer, 999)
    bole.addClickEvent(myBg, function() end, 'x', false)

    local ndButton = cc.Label:create()
    ndButton:setPosition(750, 420)
    ndButton:setColor(cc.c3b(255,0,0))
    ndButton:setScale(1.2)
    ndButton:setString("退出")
    newLayer:addChild(ndButton, 10)
    bole.addClickEvent(ndButton, function()
        newLayer:removeFromParent()
    end)

    selfConfig.actLayer = newLayer
end

selfConfig.createActScrollView = function()
    if not selfConfig.actLayer then
        return
    end
    local actLayer = selfConfig.actLayer
    local scrollViews = ccui.ScrollView:create()
    
    scrollViews:setName("scrollView1")
    scrollViews:setTouchEnabled(true)
    scrollViews:setBounceEnabled(true)
    scrollViews:setDirection(1) --vertical
    scrollViews:setColor(cc.c3b(255, 0 ,0))
    scrollViews:setContentSize(cc.size(400, 400))
    scrollViews:setInnerContainerSize(cc.size(400, 800))
    scrollViews:setPosition(cc.p(220, 100))
    scrollViews:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
    scrollViews:setBackGroundColor(cc.c3b(255, 0, 0));
    local container = scrollViews:getInnerContainer()
    container:setTouchEnabled(true)
    container:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
    container:setBackGroundColor(cc.c3b(0, 0, 255));

    actLayer:addChild(scrollViews, 2)
    selfConfig.actScroll = scrollViews
end

selfConfig.addInfoInScroll = function()
    local actNameList = {
        [1] = "SpecialOfferAct",
        [2] = "SpecialOfferTheme",
        [3] = "LoadingPic",
        [4] = "LobbyBg",
        [5] = "Coupon"
    }

    local actScroll = selfConfig.actScroll
    for idx, actName in ipairs(actNameList) do
        local labelBar = selfConfig.UnitItem.new(actName)
        if labelBar then
            labelBar:setAnchorPoint(cc.p(0, 0))
            labelBar:setPosition(cc.p(80, 700 - 60 * (idx - 1)))
            actScroll:addChild(labelBar)
        end
    end
end

selfConfig.UnitItem = class("SelfConfigUnitInActScroll", function()
    return cc.Node:create()
end)

function selfConfig.UnitItem:ctor(actName)
    self.actName = actName
    self:loadControl()
end

function selfConfig.UnitItem:loadControl()
    local actLabel = cc.Label:create()
    local inputText = ccui.TextField:create()

    self:addChild(actLabel)
    self:addChild(inputText)

    actLabel:setString(self.actName .. ":  ")
    actLabel:setScale(2)
    inputText:setPlaceHolder("输入活动的时间")
    inputText:setPosition(cc.p(200, 0))

    local textFieldEvent = function(sender, eventType)

        if eventType == ccui.TextFiledEventType.detach_with_ime then
            return
        elseif eventType == ccui.TextFiledEventType.insert_text then
            local strTime = sender:getString()
            local year, mon, mday, hour = string.match(strTime, "(%d+)-(%d+)-(%d+)-(%d+)")
            if not year or not mon or not mday then return end
            log.d("preTime", strTime, year, mon, mday, hour)
            local targetTime = os.time{year = year, month = mon, day = mday, hour = hour}
            inputText:setString(strTime)
            cc.UserDefault:getInstance():setBoolForKey("selfConfig_assignActDate", true)
            cc.UserDefault:getInstance():setIntegerForKey("selfConfig_actName_" .. self.actName, targetTime)
        elseif eventType == ccui.TextFiledEventType.attach_with_ime then
            return
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            local strTime = sender:getString()
            local year, mon, mday, hour = string.match(strTime, "(%d+)-(%d+)-(%d+)")
            hour = hour or 15
            log.d("preTime", strTime, year, mon, mday, hour)
            if not year or not mon or not mday then return end
            local targetTime = os.time{year = year, month = mon, day = mday, hour = hour}
            inputText:setString(strTime)
            cc.UserDefault:getInstance():setBoolForKey("selfConfig_assignActDate", true)
            cc.UserDefault:getInstance():setIntegerForKey("selfConfig_actName_" .. self.actName, targetTime)
            return
        end
    end
    inputText:addEventListener(textFieldEvent)
end

selfConfig.getActTime = function(actName)
    if actName == nil then return nil end
    if cc.UserDefault:getInstance():getBoolForKey("selfConfig_assignActDate", false) == false then
        return nil
    end
    local time = cc.UserDefault:getInstance():getIntegerForKey("selfConfig_actName_" .. actName)
    log.d("getTime" .. actName , time)
    return time == 0 and nil or time
end

--End

-- selfConfig.serverChooser = nil

selfConfig.salePromotionChoose = function(layerRoot)
    local saleRoot = cc.Node:create()
    saleRoot:setPosition(100, 300)
    layerRoot:addChild(saleRoot, 1)

    local isAssignSaleDate = cc.UserDefault:getInstance():getBoolForKey("selfConfig_isAssignSaleData", false)

    local salePre = cc.Label:create()
    salePre:setPosition(cc.p(0, 0)) -- 600, 40
    salePre:setColor(cc.c3b(0, 255, 0))
    salePre:setScale(2)
    local inputText = ccui.TextField:create()
    inputText:setPosition(10, -60)
    local textFieldEvent = function(sender, eventType)
        local str = sender:getString()
        if str == "" then
            isAssignSaleDate = true
        end
        log.d("接收的时间串", str, eventType)
        if eventType == ccui.TextFiledEventType.detach_with_ime then
            return
        elseif eventType == ccui.TextFiledEventType.insert_text then
            inputText:setString(str)
            cc.UserDefault:getInstance():setBoolForKey("selfConfig_isAssignSaleData", true)
            cc.UserDefault:getInstance():setStringForKey("selfConfig_saleData", str)
        elseif eventType == ccui.TextFiledEventType.attach_with_ime then
            return
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            inputText:setString(str) --may be bug in here,but modify in next time, beacause I'm a little tired
            cc.UserDefault:getInstance():setBoolForKey("selfConfig_isAssignSaleData", true)
            cc.UserDefault:getInstance():setStringForKey("selfConfig_saleData", str)
            return
        end
    end
    inputText:addEventListener(textFieldEvent)
    inputText:setAnchorPoint(cc.p(0.5, 0.5))

    local tips = cc.Label:create()
    tips:setString("输入格式 month-day(02-06):  ")
    tips:setPosition(0, -30)

    saleRoot:addChild(salePre, 1)
    saleRoot:addChild(inputText, 1)
    saleRoot:addChild(tips, 1)

    local dayCnt = cc.UserDefault:getInstance():getStringForKey("selfConfig_saleData", "")
    salePre:setString(isAssignSaleDate  and ("促销日期已确认" .. dayCnt) or "促销日期默认为12-29号")
    inputText:setVisible(false)
    bole.addClickEvent(salePre, function()
        isAssignSaleDate = not isAssignSaleDate
        salePre:setString(isAssignSaleDate  and "请输入指定日期" or "请输入更改日期")
        inputText:setVisible(true)
        local parent = salePre:getParent():getParent()
        if bole.isValidNode(parent) then
            local cdNode = parent:getChildByName("cdLabel")
            _ = bole.isValidNode(cdNode) and cdNode:removeFromParent()
        end
    end)
end


selfConfig.serverList = {
    {Ip = "123.56.7.6", Port = 1240, Name = "促销"},
    {Ip = "123.56.7.6", Port = 1263, Name = "张国超"}, -- 张国超
    -- {Ip = "89.31.136.1", Port = 1244, Name = "梁林"}, -- 梁林
    {Ip = "123.56.7.6", Port = 1244, Name = "梁林"}, -- 梁林
    {Ip = "123.56.7.6", Port = 1245, Name = "梁林"}, -- 梁林
    {Ip = "123.56.7.6", Port = 1248, Name = "于海明"}, -- 于海明
    {Ip = "123.56.7.6", Port = 1249, Name = "于海明"}, -- 于海明
    {Ip = "123.56.7.6", Port = 1251, Name = "....."},
    {Ip = "123.56.7.6", Port = 1258, Name = "yuka"}, -- yuka
    {Ip = "123.56.7.6", Port = 1273, Name = "李昌育1"}, -- 李昌育
    {Ip = "123.56.7.6", Port = 1275, Name = "李昌育2"}, -- 李昌育
    {Ip = "123.56.7.6", Port = 1276, Name = "李淑静"}, 
    {Ip = "123.56.7.6", Port = 1277, Name = "李淑静"}, 
    {Ip = "123.56.7.6", Port = 1278, Name = "李淑静"}, 
    {Ip = "123.56.7.6", Port = 1282, Name = "陈翔宇"}, 
    {Ip = "tester.boledragon.com", Port = 1231, Name = "测试服"},
    {Ip = "server.lotsa.boledragon.com", Port = 1235, Name = "正式服"},
    {Ip = "tester.boledragon.com", Port = 1241, Name = "印度服"},
}

selfConfig.codeChecker = {
    md5 = Config.codeMd5,
    run = function ()
        local oldCodeVersion = nil
        local runRet = nil
        bole.loopCall(60, function ()
            if runRet then return runRet end
            local xhr = cc.XMLHttpRequest:new()
            xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
            xhr:open('GET', selfConfig.codeChecker.md5)
            local onReadyStateChange = function ()
                if xhr.status == 200 then
                    local newCodeVersion = tostring(xhr.response)
                    print('codeChecker old:',oldCodeVersion)
                    print('codeChecker new:',newCodeVersion)
                    if oldCodeVersion and newCodeVersion ~= oldCodeVersion then
                        DebugTool:showNewCodeTips()
                        runRet = 'break'
                    else
                        oldCodeVersion = newCodeVersion
                    end
                end
            end
            xhr:registerScriptHandler(onReadyStateChange)
            xhr:send()
        end)
    end
}
-- selfConfig.codeChecker = nil