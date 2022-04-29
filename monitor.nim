import httpclient, json, strutils, strformat, times

const validators = @[xxxx, xxxxx]
const chatId = xxxxxx
const telegramKey = "xxxxx:xxxxxxxxxxx"

proc telegram(client: var HttpClient, msg: string) = 
  var data = newMultipartData()
  data["chat_id"] = $chatId
  data["disable_web_page_preview"] = "1"
  data["text"] = msg
  
  discard client.postContent(fmt"https://api.telegram.org/bot{telegramKey}/sendMessage", multipart=data)

var client = newHttpClient()

try:
  let validatorsConcat = validators.join(",")
  let latestEpochNumber = client.getContent("https://prater.beaconcha.in/api/v1/epoch/latest").parseJson()["data"]["epoch"].getInt()
  let prevEpochNumber = latestEpochNumber - 1
  
  let attestations = client.getContent(fmt"https://prater.beaconcha.in/api/v1/validator/{validatorsConcat}/attestations").parseJson()["data"]
  if attestations.kind == JNull or attestations.len == 0: raise newException(IOError, "No validator data returned from prater.beaconcha.in API")

  for attestation in attestations:
    if attestation["epoch"].getInt() == prevEpochNumber:
      let status = attestation["status"].getInt()
      let validatorindex = attestation["validatorindex"].getInt()
      if status != 1:
        let msg = fmt"Validator {validatorindex} missed an attestation at epoch {prevEpochNumber}"
        echo $now().utc & " " & msg
        client.telegram(msg)
  
  var proposedBlocks = client.getContent(fmt"https://prater.beaconcha.in/api/v1/validator/{validatorsConcat}/proposals").parseJson()["data"]
  if proposedBlocks.kind == JNull: raise newException(IOError, "No block data returned from beaconcha.in API")

  if proposedBlocks.kind != JArray:
    var tmpArr = newJArray()
    tmpArr.elems.add(proposedBlocks)
    proposedBlocks = tmpArr

  for proposal in proposedBlocks:
    if proposal["epoch"].getInt() != prevEpochNumber: continue
    let status = proposal["status"].getStr()
    let validatorindex = proposal["proposer"].getInt()

    if status != "1":
      let msg =  fmt"Validator {validatorindex} failed block proposal at {prevEpochNumber}"
      echo $now().utc & " " & msg
      client.telegram(msg)

except:
  echo $now().utc & " " & getCurrentExceptionMsg()
  try: 
    client.telegram(getCurrentExceptionMsg())
  except:
    echo $now().utc & " TELEGRAM UNAVAILABLE: " & getCurrentExceptionMsg()
