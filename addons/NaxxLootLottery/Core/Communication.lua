-- ============================================================
-- Naxxramas Loot Ledger
-- Core/Communication.lua
--
-- Phase 5 addon-to-addon wishlist transfer for WoW 3.3.5a.
--
-- IMPORTANT:
-- 3.3.5a uses global SendAddonMessage().
-- RegisterAddonMessagePrefix() was added later and is NOT used.
-- ============================================================

local NLL = NaxxLootLottery

NLL.Communication = NLL.Communication or {}
local Comm = NLL.Communication

Comm.prefix = "NLL"
Comm.protocol = "V1"
Comm.incoming = {}
Comm.pendingOutgoing = nil
Comm.timeoutSeconds = 6
Comm.initialized = false

local function Split(text, delimiter)
    local output = {}
    local pattern =
        "([^" .. delimiter .. "]*)"

    local start = 1

    while true do
        local pos =
            string.find(
                text,
                delimiter,
                start,
                true
            )

        if pos then
            table.insert(
                output,
                string.sub(
                    text,
                    start,
                    pos - 1
                )
            )
            start = pos + 1
        else
            table.insert(
                output,
                string.sub(text, start)
            )
            break
        end
    end

    return output
end

local function CleanName(name)
    if not name then
        return ""
    end

    -- 3.3.5 characters are normally not realm-qualified,
    -- but strip a suffix defensively if present.
    return string.match(name, "^([^%-]+)")
        or name
end

function Comm:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
end

function Comm:IsInRaid()
    return GetNumRaidMembers
        and (GetNumRaidMembers() or 0) > 0
end

function Comm:GetRaidLeaderName()
    if not self:IsInRaid() then
        return nil
    end

    local count = GetNumRaidMembers() or 0

    for i = 1, count do
        local name, rank =
            GetRaidRosterInfo(i)

        if name and rank == 2 then
            return CleanName(name)
        end
    end

    return nil
end

function Comm:IsSelfRaidLeader()
    local leader = self:GetRaidLeaderName()
    local player = UnitName("player")

    return leader
        and player
        and string.lower(leader)
            == string.lower(player)
end

function Comm:IsSenderInRaid(sender)
    sender = CleanName(sender)

    local count = GetNumRaidMembers
        and (GetNumRaidMembers() or 0)
        or 0

    for i = 1, count do
        local name = GetRaidRosterInfo(i)

        if name
            and string.lower(CleanName(name))
                == string.lower(sender) then

            return true
        end
    end

    return false
end

function Comm:IsSenderCurrentRaidLeader(sender)
    local leader = self:GetRaidLeaderName()

    if not leader then
        return false
    end

    return
        string.lower(CleanName(sender))
        == string.lower(leader)
end

function Comm:SendWhisper(target, text)
    if not target or target == "" then
        return false
    end

    if not SendAddonMessage then
        NLL:Print(
            "ERROR: SendAddonMessage is unavailable."
        )
        return false
    end

    if string.len(text or "") > 240 then
        NLL:Print(
            "ERROR: Refusing an oversized addon message."
        )
        return false
    end

    SendAddonMessage(
        self.prefix,
        text,
        "WHISPER",
        target
    )

    return true
end

function Comm:BuildLocalWishlistItemIDs()
    local output = {}
    local player = UnitName("player")

    if not player then
        return output
    end

    local wishlist =
        NLL.Database:GetLocalWishlist(
            player,
            "MOLTEN_CORE"
        )

    for itemID, wanted in pairs(wishlist or {}) do
        if wanted
            and NLL.Data.MoltenCore:GetItem(
                tonumber(itemID)
            ) then

            table.insert(
                output,
                tonumber(itemID)
            )
        end
    end

    table.sort(output)
    return output
end

function Comm:CreateSubmissionID()
    local player =
        UnitName("player") or "Player"

    return
        string.sub(player, 1, 12) ..
        tostring(
            math.floor(
                (GetTime() or 0) * 1000
            )
        )
end

function Comm:SubmitLocalWishlist()
    if not self:IsInRaid() then
        NLL:Print(
            "You must be in a raid to submit a wishlist."
        )
        return
    end

    local leader = self:GetRaidLeaderName()

    if not leader then
        NLL:Print(
            "No raid leader could be identified."
        )
        return
    end

    local itemIDs =
        self:BuildLocalWishlistItemIDs()

    if #itemIDs == 0 then
        NLL:Print(
            "Your Molten Core wishlist is empty."
        )
        return
    end

    local player = UnitName("player")

    if player
        and string.lower(player)
        == string.lower(leader) then

        -- Local fast path for a raid leader submitting
        -- their own wishlist.
        local submissionID =
            self:CreateSubmissionID()

        self:StoreInboxSubmission(
            submissionID,
            player,
            "MOLTEN_CORE",
            itemIDs
        )

        NLL:Print(
            tostring(#itemIDs) ..
            " local wishlist item(s) added to your inbox."
        )

        self:RefreshUI()
        return
    end

    local submissionID =
        self:CreateSubmissionID()

    self.pendingOutgoing = {
        submissionID = submissionID,
        leader = leader,
        raidKey = "MOLTEN_CORE",
        itemIDs = itemIDs,
        state = "WAIT_HELLO",
        startedAt = GetTime()
    }

    self:SendWhisper(
        leader,
        self.protocol .. "|HELLO"
    )

    NLL:Print(
        "Checking for a compatible NLL raid leader..."
    )

    self:RefreshUI()
end

function Comm:SendPendingWishlist()
    local pending = self.pendingOutgoing

    if not pending then
        return
    end

    local leader = pending.leader
    local submissionID =
        pending.submissionID

    self:SendWhisper(
        leader,
        self.protocol ..
        "|BEGIN|" ..
        submissionID ..
        "|" ..
        pending.raidKey ..
        "|" ..
        tostring(#pending.itemIDs)
    )

    for i = 1, #pending.itemIDs do
        self:SendWhisper(
            leader,
            self.protocol ..
            "|ITEM|" ..
            submissionID ..
            "|" ..
            tostring(i) ..
            "|" ..
            tostring(pending.itemIDs[i])
        )
    end

    self:SendWhisper(
        leader,
        self.protocol ..
        "|END|" ..
        submissionID
    )

    pending.state = "WAIT_ACK"
    pending.startedAt = GetTime()

    NLL:Print(
        "Wishlist sent. Waiting for acknowledgement..."
    )

    self:RefreshUI()
end

function Comm:HandleHello(sender)
    if not self:IsSelfRaidLeader() then
        return
    end

    if not self:IsSenderInRaid(sender) then
        return
    end

    self:SendWhisper(
        CleanName(sender),
        self.protocol .. "|HELLO_ACK"
    )
end

function Comm:HandleHelloAck(sender)
    local pending = self.pendingOutgoing

    if not pending
        or pending.state ~= "WAIT_HELLO" then
        return
    end

    if not self:IsSenderCurrentRaidLeader(sender) then
        return
    end

    if string.lower(CleanName(sender))
        ~= string.lower(pending.leader) then
        return
    end

    self:SendPendingWishlist()
end

function Comm:HandleBegin(
    sender,
    submissionID,
    raidKey,
    countText
)
    if not self:IsSelfRaidLeader() then
        return
    end

    if not self:IsSenderInRaid(sender) then
        return
    end

    if raidKey ~= "MOLTEN_CORE" then
        return
    end

    local expectedCount =
        tonumber(countText)

    if not expectedCount
        or expectedCount < 0
        or expectedCount > 200 then
        return
    end

    local senderName =
        CleanName(sender)

    local key =
        string.lower(senderName) ..
        "|" ..
        submissionID

    self.incoming[key] = {
        submissionID = submissionID,
        player = senderName,
        raidKey = raidKey,
        expectedCount = expectedCount,
        items = {},
        receivedIndexes = {},
        startedAt = GetTime()
    }
end

function Comm:HandleItem(
    sender,
    submissionID,
    indexText,
    itemIDText
)
    if not self:IsSelfRaidLeader() then
        return
    end

    local senderName =
        CleanName(sender)

    local key =
        string.lower(senderName) ..
        "|" ..
        submissionID

    local incoming =
        self.incoming[key]

    if not incoming then
        return
    end

    local index = tonumber(indexText)
    local itemID = tonumber(itemIDText)

    if not index
        or index < 1
        or index > incoming.expectedCount then
        return
    end

    if not itemID
        or not NLL.Data.MoltenCore:GetItem(
            itemID
        ) then
        return
    end

    if incoming.receivedIndexes[index] then
        return
    end

    incoming.receivedIndexes[index] = true
    incoming.items[index] = itemID
end

function Comm:HandleEnd(sender, submissionID)
    if not self:IsSelfRaidLeader() then
        return
    end

    local senderName =
        CleanName(sender)

    local key =
        string.lower(senderName) ..
        "|" ..
        submissionID

    local incoming =
        self.incoming[key]

    if not incoming then
        return
    end

    local itemIDs = {}

    for i = 1, incoming.expectedCount do
        local itemID = incoming.items[i]

        if not itemID then
            self.incoming[key] = nil
            return
        end

        table.insert(itemIDs, itemID)
    end

    self:StoreInboxSubmission(
        incoming.submissionID,
        senderName,
        incoming.raidKey,
        itemIDs
    )

    self.incoming[key] = nil

    self:SendWhisper(
        senderName,
        self.protocol ..
        "|ACK|" ..
        submissionID ..
        "|" ..
        tostring(#itemIDs)
    )

    NLL:Print(
        "Wishlist received from " ..
        senderName ..
        ": " ..
        tostring(#itemIDs) ..
        " item(s)."
    )

    self:RefreshUI()
end

function Comm:HandleAck(
    sender,
    submissionID,
    countText
)
    local pending = self.pendingOutgoing

    if not pending
        or pending.state ~= "WAIT_ACK"
        or pending.submissionID ~= submissionID then
        return
    end

    if not self:IsSenderCurrentRaidLeader(sender) then
        return
    end

    local count = tonumber(countText) or 0

    NLL:Print(
        tostring(count) ..
        " Molten Core item(s) successfully submitted to " ..
        CleanName(sender) ..
        "."
    )

    self.pendingOutgoing = nil
    self:RefreshUI()
end

function Comm:HandleAddonMessage(
    prefix,
    message,
    channel,
    sender
)
    if prefix ~= self.prefix then
        return
    end

    if type(message) ~= "string"
        or string.len(message) > 240 then
        return
    end

    if channel ~= "WHISPER"
        and channel ~= "RAID" then
        return
    end

    local fields = Split(message, "|")

    if fields[1] ~= self.protocol then
        return
    end

    local command = fields[2]

    if command == "HELLO" then
        self:HandleHello(sender)
        return
    end

    if command == "HELLO_ACK" then
        self:HandleHelloAck(sender)
        return
    end

    if command == "BEGIN"
        and fields[3]
        and fields[4]
        and fields[5] then

        self:HandleBegin(
            sender,
            fields[3],
            fields[4],
            fields[5]
        )
        return
    end

    if command == "ITEM"
        and fields[3]
        and fields[4]
        and fields[5] then

        self:HandleItem(
            sender,
            fields[3],
            fields[4],
            fields[5]
        )
        return
    end

    if command == "END"
        and fields[3] then

        self:HandleEnd(
            sender,
            fields[3]
        )
        return
    end

    if command == "ACK"
        and fields[3]
        and fields[4] then

        self:HandleAck(
            sender,
            fields[3],
            fields[4]
        )
        return
    end
end

function Comm:StoreInboxSubmission(
    submissionID,
    playerName,
    raidKey,
    itemIDs
)
    local key =
        string.lower(playerName) ..
        "|" ..
        submissionID

    NLL.db.submissionInbox[key] = {
        key = key,
        submissionID = submissionID,
        player = playerName,
        raidKey = raidKey,
        itemIDs = itemIDs,
        excluded = {},
        status = "PENDING",
        receivedAt =
            date("%d/%m/%Y %H:%M"),
        receivedEpoch =
            time()
    }

    return NLL.db.submissionInbox[key]
end

function Comm:GetInboxSubmissions()
    local output = {}

    for key, submission
        in pairs(NLL.db.submissionInbox or {}) do

        if type(submission) == "table" then
            submission.key = key
            table.insert(output, submission)
        end
    end

    table.sort(output, function(a, b)
        return
            (a.receivedEpoch or 0)
            > (b.receivedEpoch or 0)
    end)

    return output
end

function Comm:GetSubmission(key)
    return
        NLL.db.submissionInbox
        and NLL.db.submissionInbox[key]
end

function Comm:GetIncludedItemIDs(submission)
    local itemIDs = {}

    if not submission then
        return itemIDs
    end

    submission.excluded =
        submission.excluded or {}

    for i = 1, #(submission.itemIDs or {}) do
        local itemID =
            submission.itemIDs[i]

        if not submission.excluded[itemID] then
            table.insert(itemIDs, itemID)
        end
    end

    return itemIDs
end

function Comm:GetConflictCount(submission)
    local count = 0

    if not submission then
        return 0
    end

    local itemIDs =
        self:GetIncludedItemIDs(submission)

    for i = 1, #itemIDs do
        local conflict =
            NLL.GearNeeds:HasOtherSourceNeed(
                submission.player,
                submission.raidKey,
                itemIDs[i]
            )

        if conflict then
            count = count + 1
        end
    end

    return count
end

function Comm:ToggleExcludedItem(
    submissionKey,
    itemID
)
    local submission =
        self:GetSubmission(submissionKey)

    if not submission
        or submission.status ~= "PENDING" then
        return
    end

    submission.excluded =
        submission.excluded or {}

    itemID = tonumber(itemID)

    if submission.excluded[itemID] then
        submission.excluded[itemID] = nil
    else
        submission.excluded[itemID] = true
    end

    self:RefreshUI()
end

function Comm:AcceptSubmission(key)
    local submission =
        self:GetSubmission(key)

    if not submission
        or submission.status ~= "PENDING" then
        return false
    end

    local itemIDs =
        self:GetIncludedItemIDs(submission)

    local added, conflicts =
        NLL.GearNeeds:ReplacePlayerSubmitted(
            submission.player,
            submission.raidKey,
            itemIDs
        )

    submission.status = "ACCEPTED"
    submission.acceptedAt =
        date("%d/%m/%Y %H:%M")
    submission.acceptedCount = added
    submission.conflictCount = conflicts

    NLL:Print(
        "Accepted " ..
        tostring(added) ..
        " wishlist item(s) from " ..
        submission.player ..
        "."
    )

    self:RefreshUI()
    return true
end

function Comm:RejectSubmission(key)
    local submission =
        self:GetSubmission(key)

    if not submission
        or submission.status ~= "PENDING" then
        return false
    end

    submission.status = "REJECTED"
    submission.rejectedAt =
        date("%d/%m/%Y %H:%M")

    NLL:Print(
        "Rejected wishlist submission from " ..
        submission.player ..
        "."
    )

    self:RefreshUI()
    return true
end

function Comm:GetOutgoingStatusText()
    local pending = self.pendingOutgoing

    if not pending then
        return "No submission currently pending."
    end

    if pending.state == "WAIT_HELLO" then
        return
            "Checking raid leader addon compatibility..."
    end

    if pending.state == "WAIT_ACK" then
        return
            "Wishlist sent; waiting for receipt acknowledgement..."
    end

    return "Submission in progress."
end

function Comm:RefreshUI()
    if not NLL.UI then
        return
    end

    if NLL.UI.RefreshWishlistPanel then
        NLL.UI:RefreshWishlistPanel()
    end
end

-- ============================================================
-- EVENTS
-- ============================================================

local eventFrame = CreateFrame("Frame")
Comm.eventFrame = eventFrame

eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if not NLL.initialized then
            return
        end

        if event == "CHAT_MSG_ADDON" then
            Comm:HandleAddonMessage(...)
        end
    end
)

-- 3.3.5a has no C_Timer.  Use a small OnUpdate timeout check.
local timeoutFrame = CreateFrame("Frame")
Comm.timeoutFrame = timeoutFrame
timeoutFrame.elapsed = 0

timeoutFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)
        self.elapsed =
            self.elapsed + elapsed

        if self.elapsed < 0.5 then
            return
        end

        self.elapsed = 0

        local pending =
            Comm.pendingOutgoing

        if pending
            and pending.startedAt
            and (
                (GetTime() - pending.startedAt)
                >= Comm.timeoutSeconds
            ) then

            if pending.state == "WAIT_HELLO" then
                NLL:Print(
                    "No compatible Naxxramas Loot Ledger raid leader was detected."
                )
            else
                NLL:Print(
                    "Wishlist submission acknowledgement timed out."
                )
            end

            Comm.pendingOutgoing = nil
            Comm:RefreshUI()
        end
    end
)
