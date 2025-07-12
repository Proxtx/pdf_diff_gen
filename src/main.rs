use clap::Parser;
use std::{path::PathBuf, sync::Arc};

mod files;
mod pdf;

#[derive(Debug, Parser)]
#[command(version, about, long_about = None)]
struct Args {
    current_path: PathBuf,
    last_path: PathBuf,
    diff_path: PathBuf,
    pdfium_path: PathBuf,
    interval: humantime::Duration,
}

#[tokio::main]
async fn main() {
    let args = Args::parse();

    let pdfium = Arc::new(
        pdf::get_pdfium(&args.pdfium_path).expect("Unable to load PDFium from provided Path"),
    );

    let file_manager =
        files::FileManager::new(pdfium, args.current_path, args.last_path, args.diff_path);

    loop {
        match file_manager.update().await {
            Ok(v) => {
                v.iter().for_each(|(path, result)| match result {
                    Ok(v) => println!(
                        "Updated {} successfully to {}",
                        path.to_string_lossy(),
                        v.to_string_lossy()
                    ),
                    Err(e) => println!(
                        "Unable to update {}. FileManagerError: {}",
                        path.to_string_lossy(),
                        e
                    ),
                });
            }
            Err(e) => {
                println!("Error updating pdf. FileManagerError: {}", e)
            }
        }

        tokio::time::sleep(args.interval.into()).await;
    }
}
