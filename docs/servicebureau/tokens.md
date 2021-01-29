# Access Token Limits - Lab Summary

* Discover how you can restrict usage by creating separate access tokens and set limits.

## 1. Controlling usage

If you wish to control the consumption of Hosts, Containers, Custom Metrics and High Resolution Metrics, you can create multiple Access Tokens and allocate them to different parts of your organization.

Assuming you are still within the Organization Overview section, simply select the **Access Tokens** tab from the left pane.

![Select Token](../images/servicebureau/access-tokens-menu.png)

However to get to this section from anywhere click on **Settings** (icon at the top right top of the page) and select **Organizations Settings → Access tokens**

The **Access Tokens** Interface provides an overview of your Allotments in the form of a list of Access Tokens that have been generated. Every Organization will have a **Default** token generated when they are first setup, but there will typically be multiple Tokens configured.

Each Token is unique and can be assigned limits for the amount of Hosts, Containers, Custom Metrics and High Resolution Metrics it can consume.

The **Usage Status** Column quickly shows if a token is above or below its assigned limits.

![New token](../images/servicebureau/access-tokens.png){: .zoom}

### 1.1 Creating a new token

Let create a new token by clicking on  the **New Token**{: .label-button .sfx-ui-button-blue} button. This will provide you with the **Name Your Access Token** dialog.

Enter the new name of the new Token by using your Initials e.g. RWC-Token

![Name Your token](../images/servicebureau/new-access-token.png){: .shadow}

After you press Ok,  you will be taken back to the **Access Token** UI, here your new token should be present, among the ones created by others.

![full tokenlist](../images/servicebureau/access-token-created.png){: .zoom}

If you have made an error in your naming, want to disable/enable a token or set a Token limit, click on the ellipsis (**...**) menu button behind a token limit to open the manage token menu.

![Show Menu](../images/servicebureau/manage-access-token.png){: .zoom}

If you made a typo you can use the Rename Token option to correct the name of your token.

### 1.2 Disabling a token

If you need to make sure a token cannot be used to send Metrics in you can Disable a token.

Click on the Disable button to Disable the token, this means the token cannot be used for sending in data to SignalFX.

The line with Your Token should become greyed out to indicate that is has been Disabled as you can see in the screenshot below.

![Token disabled](../images/servicebureau/disable-access-token.png){: .zoom}

Go ahead and click on the ellipsis (**...**) menu button to Disable and Enable your token.

### 1.3 Manage token usage limits

Now Lets start limiting usage by clicking on Manage Token Limit in the 3 **...** menu.

This will show the Manage Token Limit Dialog:

![Set Limits on token](../images/servicebureau/manage-token-limit.png){: .shadow}

In this Dialog you can set the limits per category.

Please go ahead and specify the limits as follows for each usage metric:

| Limit | Value |
| ----- | ----- |
| Host Limit | 5 |
| Container Limit | 15 |
| Custom Metric Limit | 20 |
| High Resolution Metric Limit | 0 |

For our lab use your own email address, and double check that you have the correct numbers in your dialog box as shown in the table above.

Token limits are used to trigger an alert that notify one or more recipients when the usage has been above 90% of the limit for 5 minutes.

To specify the recipients, click **Add Recipient**{: .label-button .sfx-ui-button-blue}, then select the recipient or notification method you want to use (specifying recipients is optional but highly recommended).

The severity for token alerts is always Critical.

Click on **Update**{: .label-button .sfx-ui-button-blue} to save your Access Tokens limits and The Alert Settings.

!!! note "Going above token limit"
    When a token is at or above its limit in a usage category, new metrics for that usage category will not be stored and processed by SignalFx. This will make sure you there  will be no unexpected cost due to a team sending in data without restriction.

!!! note "Advanced alerting"
    If you wish to get alerts before you hit 90%, you can create additional detectors using whatever values you want. These detectors could target the Teams consuming the specific Access Tokens so they can take action before the admins need to get involved.

In your company you would distribute these new Access Tokens to various teams, controlling how much information/data they can send to SignalFx.

This will allow you to fine tune the way you consume your SignalFx allotment and prevent overages from happening.

**Congratulations!** You have now have completed the Service Bureau module.