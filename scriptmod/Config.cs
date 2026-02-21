using System.Text.Json.Serialization;

namespace adamantris.MapGlueAPI;

public class Config(ConfigFileSchema configFile)
{
	[JsonInclude]
	public bool infiniteChatRange = configFile.infiniteChatRange;
}
